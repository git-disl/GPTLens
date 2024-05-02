import gradio as gr
import os
import run_auditor_user_defined
import run_critic_user_defined
import run_rank
import pre_process
from utils import dotdict, clean_folder

os.environ['DISPLAY'] = ':0'

def openAIKey(key):
    if key:
        os.environ["OPENAI_API_KEY"] = key
        return "Let's get you started"
    else:
        return "Please add your OpenAI API key to continue."


def auditor(key, audit_model, audit_top_k, audit_temperature, audit_number, audit_contract_file, audit_prompt_file):
    if audit_contract_file:
        args = {
            'backend': audit_model.lower(),
            'temperature': audit_temperature,
            'data_dir': "data/CVE_clean",
            'topk': audit_top_k,
            'num_auditor': audit_number,
            'openai_api_key': key
        }
        args = dotdict(args)

        if os.path.exists("data/CVE"):
            clean_folder("data/CVE")
        if os.path.exists("data/CVE_clean"):
            clean_folder("data/CVE_clean")
        if os.path.exists(f"src/logs/auditor_{args.backend}_{args.temperature}_top{args.topk}_{args.num_auditor}"):
            clean_folder(f"src/logs/auditor_{args.backend}_{args.temperature}_top{args.topk}_{args.num_auditor}")

        for uploaded_file in audit_contract_file:
            file_name_int = uploaded_file.rfind("/") + 1
            name = uploaded_file[file_name_int:len(uploaded_file)]
            fp = open(uploaded_file, 'rb')
            bytes_data = fp.read()
            with open(f"data/CVE/{name}", "wb") as f:
                f.write(bytes_data)
        
        ## Pre processing the data        
        pre_process.mainfnc(args.data_dir)

        if audit_prompt_file:
            for uploaded_file in audit_prompt_file:
                file_name_int = uploaded_file.rfind("/") + 1
                name = uploaded_file[file_name_int:len(uploaded_file)]
                fp = open(uploaded_file, 'rb')
                bytes_data = fp.read()
                with open(f"src/prompt.py", "wb") as f:
                    f.write(bytes_data)
        
        ## Running the auditor code
        run_auditor_user_defined.mainfnc(args)

        message = f"You can find your processed Audit files at ./src/logs/auditor_{args.backend}_{args.temperature}_top{args.topk}_{args.num_auditor}"
    else:
        message = "Please Upload the Contract Files to proceed"
    
    return message



def critic(key, critic_model, critic_shots, critic_temperature, critic_number, critic_auit_directory):
    if critic_auit_directory:
        args = {
            'backend': critic_model.lower(),
            'temperature': critic_temperature,
            'dataset': "CVE",
            'auditor_dir': critic_auit_directory,
            'num_critic': critic_number,
            'shot': critic_shots.lower(),
            'openai_api_key': key
        }
        args = dotdict(args)

        run_critic_user_defined.mainfnc(args)
        message = f"Critic files processed successfully to folder ./src/logs/{args.auditor_dir}/critic_{args.backend}_{args.temperature}_{args.num_critic}_{args.shot}"
    else:
        message = "Please add the Audit Directory value to proceed"

    return message


def ranker(critic_model, critic_shots, critic_temperature, critic_number, critic_auit_directory, ranker_strategy, ranker_audit_location, ranker_critic_location):
    if critic_auit_directory and ranker_audit_location:
        args_c = {
            'auditor_dir': critic_auit_directory,
            'backend':critic_model.lower(),
            'temperature':critic_temperature,
            'num_critic': critic_number,
            'shot': critic_shots.lower()
        }

        args_r = {
            'auditor_dir': ranker_audit_location,
            'critic_dir': ranker_critic_location,
            'strategy': ranker_strategy.lower()
        }
        args_r = dotdict(args_r)
        args_c = dotdict(args_c)

        run_rank.mainfnc(args_r)
        message = f"Ranking files processed successfully to folder ./src/logs/{args_c.auditor_dir}/critic_{args_c.backend}_{args_c.temperature}_{args_c.num_critic}_{args_c.shot}/ranker_{args_r.strategy}"
    else:
        message = "Please enter the Audit directory locations to proceed."

    return message



with gr.Blocks() as ui:
    gr.Image("src/images/header.png", min_width=1500, height=80, show_download_button=False, show_label=False)
    message = "Hello, Welcome to GPTLens GUI by Aishwarya Solanki..."
    audit_output = "Auditor hasn't run yet."
    critic_output = "Critic hasn't run yet."
    ranker_output = "Ranker hasn't run yet."

    with gr.Row(equal_height=500):
        with gr.Column(scale=1, min_width=300):
            key = gr.Textbox(label="Please input your openAi key", type="password")
            gr.Button(value="Don't have an openAi key? Get one here.", link="https://platform.openai.com/account/api-keys")
            gr.ClearButton(key, message, variant="primary")
            

        with gr.Column(scale=2, min_width=600):
            message = gr.Textbox(label="", value=message, interactive=False, visible=True)
            gr.Markdown("### Auditor")

            audit_model = gr.Radio(label="GPT Model", value="GPT-4",  choices=["GPT-3.5-Turbo", "GPT-4", "GPT-4-Turbo-Preview"])
            audit_top_k = gr.Slider(1, 10, value=3, step = 1, label="top-k value", info="Set the 'k' for top-k auditor responses")
            audit_temperature = gr.Slider(0.0, 1.0, value=0.7, step = 0.01, label="Temperature", info="Set the Temperature")
            audit_number = gr.Slider(1, 10, value=1, step = 1, label="Number of Auditors", info="Set the number of auditors")

            with gr.Row():
                with gr.Column(min_width=300, scale=2):
                    gr.Markdown("### Upload smart contract files (.sol)")
                    audit_contract_file = gr.Files()
                    audit_btn = gr.Button(value="Start Auditor", variant="primary", elem_id="audit")

                with gr.Column(min_width=300, scale=2):
                    gr.Markdown("### Upload prompt file (optional, .py)")
                    audit_prompt_file = gr.Files()
            
            audit_output = gr.Textbox(label="Auditor Status", value=audit_output, interactive=False, visible=True, elem_id="auditor_output")
            
            audit_btn.click(fn=auditor, inputs=[key, audit_model, audit_top_k, audit_temperature, 
                                                audit_number, audit_contract_file, audit_prompt_file], 
                                                outputs=audit_output, api_name="auditor")
            gr.Markdown("### Critic")
            critic_model = gr.Radio(label="GPT Model", value="GPT-4", choices=["GPT-3.5-Turbo", "GPT-4", "GPT-4-Turbo-Preview"])
            critic_shots= gr.Radio(label="Set the num of shots", value="Few", choices=["One", "Few"])
            critic_temperature = gr.Slider(0.0, 1.0, value=0.7, step = 0.01, label="Temperature", info="Set the Temperature")
            critic_number = gr.Slider(1, 10, value=1, step = 1, label="Number of Critics", info="Set the number of critics")
            critic_auit_directory = gr.Textbox(label="Auditor Directory Location", 
                                               info="Example = auditor_{audit_model}_{audit_temperature}_top{audit_top_k}_{audit_number}", 
                                               value="")

            with gr.Row():
                with gr.Column(min_width=300, scale=2):
                    critic_btn = gr.Button(value="Start Critic", variant="primary", elem_id="critic")
                with gr.Column(min_width=300, scale=2):
                    gr.Button(value="Start Ranker", variant="primary", visible=False)

            critic_output = gr.Textbox(label="Critic Status", value=critic_output, interactive=False, visible=True, elem_id="criticor_output")
            
            critic_btn.click(fn=critic, inputs=[key, critic_model, critic_shots, critic_temperature, critic_number, critic_auit_directory], 
                                                outputs=critic_output, api_name="criticor")
            
            gr.Markdown("### Ranker")
            ranker_strategy = gr.Radio(label="Strategy", value="Default", choices=["Custom", "Default"])
            ranker_audit_location = gr.Textbox(label="Auditor Directory Location", value="", 
                                               info="Example = auditor_{audit_model}_{audit_temperature}_top{audit_top_k}_{audit_number}")
            ranker_critic_location = gr.Textbox(label="Critic Directory Location",value="", 
                                                info="Example = critic_{critic_model}_{critic_temperature}_{critic_number}_{critic_shots}")
            with gr.Row():
                with gr.Column(min_width=300, scale=2):
                    ranker_btn = gr.Button(value="Start Ranker", variant="primary", elem_id="ranker")
                with gr.Column(min_width=300, scale=2):
                    gr.Button(value="Start Ranker", variant="primary", visible=False)

            ranker_output = gr.Textbox(label="Ranker Status", value=ranker_output, interactive=False, visible=True, elem_id="ranker_output")
                
            ranker_btn.click(fn=ranker, inputs=[critic_model, critic_shots, critic_temperature, critic_number, critic_auit_directory, 
                                                ranker_strategy, ranker_audit_location, ranker_critic_location], 
                                                    outputs=ranker_output, api_name="ranker")
            

            gr.Button(value="You can checkout the results at path - ./src/logs/", link="https://github.com/git-disl/GPTLens/tree/main/src/logs")
            key.change(fn=openAIKey, inputs=key, outputs=message)



ui.launch(share=True)
