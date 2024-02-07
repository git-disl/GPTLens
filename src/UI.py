import streamlit as st
import os
import zipfile
import run_auditor_user_defined
import run_critic_user_defined
import run_rank
import shutil
import time
import pre_process
from utils import dotdict, clean_folder
from streamlit_js_eval import streamlit_js_eval

os.environ['DISPLAY'] = ':0'

with st.sidebar:
    openai_api_key = st.text_input("OpenAI API Key", key="chatbot_api_key", type="password")
    "[Get an OpenAI API key](https://platform.openai.com/account/api-keys)"
    "[View the source code](https://github.com/streamlit/llm-examples/blob/main/Chatbot.py)"
    "[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/streamlit/llm-examples?quickstart=1)"
    st.divider()
    if st.button("Reset App"):
        streamlit_js_eval(js_expressions="parent.window.location.reload()")


st.title("💬 GPTLens")
st.caption("🚀 Smart Contract Vulnerability Detection powered by OpenAI LLM")

if not openai_api_key:
    st.warning("Please add your OpenAI API key to continue.")
    st.stop()
else:
    os.environ["OPENAI_API_KEY"] = openai_api_key


# Store the initial value of widgets in session state
if "visibility" not in st.session_state:
    st.session_state.visibility = "visible"
    st.session_state.disabled = False

if "start_critic" not in st.session_state:
    st.session_state.start_critic = False

if "start_auditor" not in st.session_state:
    st.session_state.start_auditor = False

if "start_ranking" not in st.session_state:
    st.session_state.start_ranking = False

if "section_active_auditor" not in st.session_state:
    st.session_state.section_active_auditor = True

if "section_active_critic" not in st.session_state:
    st.session_state.section_active_critic = False

if "section_active_ranking" not in st.session_state:
    st.session_state.section_active_ranking = False

if "args" not in st.session_state:
    st.session_state.args = None

if "args_c" not in st.session_state:
    st.session_state.args_c = None

if "args_r" not in st.session_state:
    st.session_state.args_r = None


if st.session_state.section_active_auditor:

    st.header("Auditor Step", divider=True)
    st.divider()

    col1, col2 = st.columns(2)

    with col1:
        model = st.radio(
            "Set the GPT model 👉",
            key="model",
            options=["gpt-3.5-turbo", "gpt-4", "gpt-4-turbo-preview"],
            index=2
        )
        
        uploaded_files = st.file_uploader('Upload smart contract files', accept_multiple_files=True, type=['sol'])

    with col2:
        topk =  st.number_input(
            "Set the topk auditor responses 👉",
            key="topk",
            min_value=1,
            max_value=10,
            value=3,
            format="%d"
        )

        temperature = st.number_input(
            "Set the temperature 👉",
            key="temperature",
            min_value=0.0,
            max_value=1.0,
            value=0.7,
            format="%f"
        )

        num_auditors = st.number_input(
            "Set the num auditors 👉",
            key="num_auditors",
            min_value=1,
            max_value=10,
            value=1,
            format="%d"
        )

        uploaded_prompt = st.file_uploader('Upload prompt file (optional)', accept_multiple_files=False, type=['py'])

    def start_auditor():
        st.session_state.start_auditor = True
    def end_auditor():
        st.session_state.start_auditor = False

    audit_button = st.button("Start Auditor", key="auditor", on_click=start_auditor)

    if audit_button and st.session_state.start_auditor:
        if uploaded_files:
            os.environ["OPENAI_API_KEY"] = openai_api_key
            args_dict = {
                'backend': model,
                'temperature': temperature,
                'data_dir': "data/CVE_clean",
                'topk': topk,
                'num_auditor': num_auditors,
                'openai_api_key': openai_api_key
            }
            args = dotdict(args_dict)
            st.session_state.args = args
            if os.path.exists("data/CVE"):
                clean_folder("data/CVE")
            if os.path.exists("data/CVE_clean"):
                clean_folder("data/CVE_clean")
            if os.path.exists(f"src/logs/auditor_{args.backend}_{args.temperature}_top{args.topk}_{args.num_auditor}"):
                clean_folder(f"src/logs/auditor_{args.backend}_{args.temperature}_top{args.topk}_{args.num_auditor}")
            for uploaded_file in uploaded_files:
                name = uploaded_file.name
                bytes_data = uploaded_file.read()
                with open(f"data/CVE/{name}", "wb") as f:
                    f.write(bytes_data)
            pre_process.mainfnc(args.data_dir)
            if uploaded_prompt:
                bytes_data = uploaded_prompt.read()
                with open(f"src/prompt.py", "wb") as f:
                    f.write(bytes_data)
            st.write("Starting auditor code!")
            run_auditor_user_defined.mainfnc(args)
            st.write(f"Audit files processed successfully to folder ./src/logs/auditor_{args.backend}_{args.temperature}_top{args.topk}_{args.num_auditor}!")
            end_auditor()
            time.sleep(2)
            # st.session_state.section_active_auditor = False
            st.session_state.section_active_critic= True
            uploaded_file = False
        else:
            st.warning("Please upload data zip.")
            st.stop()
    # else:
    #     st.stop()



if st.session_state.section_active_critic:

    st.header("Critic Step", divider=True)
    st.divider()

    col1, col2 = st.columns(2)

    args = st.session_state.args

    with col1:
        model_c = st.radio(
            "Set the GPT model 👉",
            key="model_c",
            options=["gpt-3.5-turbo", "gpt-4", "gpt-4-turbo-preview"],
            index=2
        )
        
        auditor_dir_c = st.text_input(
            "Auditor Directory location",
            value=f"auditor_{args.backend}_{args.temperature}_top{args.topk}_{args.num_auditor}"
        )

    with col2:

        temperature_c = st.number_input(
            "Set the temperature 👉",
            key="temperature_c",
            min_value=0.0,
            max_value=1.0,
            value=0.0,
            format="%f"
        )

        num_critic_c = st.number_input(
            "Set the num critics 👉",
            key="num_critic_c",
            min_value=1,
            max_value=10,
            value=1,
            format="%d"
        )

        shot_c = st.radio(
            "Set the num shots (few/one) 👉",
            key="shot_c",
            options=["one", "few"],
            index=1
        )

    os.environ["OPENAI_API_KEY"] = openai_api_key

    def start_critic():
        st.session_state.start_critic = True
    def end_critic():
        st.session_state.start_critic = False

    critic_button = st.button("Start Critics", key="critic", on_click=start_critic)

    if critic_button and st.session_state.start_critic:
        args_c_dict = {
            'backend': model_c,
            'temperature': temperature_c,
            'dataset': "CVE",
            'auditor_dir': auditor_dir_c,
            'num_critic': num_critic_c,
            'shot': shot_c,
            'openai_api_key': openai_api_key
        }
        args_c = dotdict(args_c_dict)
        st.session_state.args_c = args_c
        st.write("Starting critic code!")
        run_critic_user_defined.mainfnc(args_c)
        st.write(f"Critic files processed successfully to folder ./src/logs/{args_c.auditor_dir}/critic_{args_c.backend}_{args_c.temperature}_{args_c.num_critic}_{args_c.shot}!")
        end_critic()
        time.sleep(2)
        # st.session_state.section_active_critic = False
        st.session_state.section_active_ranking = True
    # else:
    #     st.stop()



if st.session_state.section_active_ranking:
    st.header("Ranking Step", divider=True)
    st.divider()

    col1, col2 = st.columns(2)

    args = st.session_state.args
    args_c = st.session_state.args_c

    with col1:
        
        auditor_dir_r = st.text_input(
            "Auditor Dir location",
            value=f"auditor_{args.backend}_{args.temperature}_top{args.topk}_{args.num_auditor}"
        )

        critic_dir_r = st.text_input(
            "Critic Directory location",
            value=f"critic_{args_c.backend}_{args_c.temperature}_{args_c.num_critic}_{args_c.shot}"
        )

    with col2:

        strategy_r = st.radio(
            "Set the strategy (default/custom) 👉",
            key="strategy_r",
            options=["default", "custom"],
            index=0
        )

    def start_ranking():
        st.session_state.start_ranking = True
    def end_ranking():
        st.session_state.start_ranking = False

    rank_button = st.button("Start Ranking", key="ranking", on_click=start_ranking)

    if rank_button and st.session_state.start_ranking:
        args_r_dict = {
            'auditor_dir': auditor_dir_r,
            'critic_dir': critic_dir_r,
            'strategy': strategy_r
        }
        args_r = dotdict(args_r_dict)
        st.session_state.args_r = args_r
        st.write(f"Starting ranking code!")
        run_rank.mainfnc(args_r)
        st.write(f"Ranking files processed successfully to folder ./src/logs/{args_c.auditor_dir}/critic_{args_c.backend}_{args_c.temperature}_{args_c.num_critic}_{args_c.shot}/ranker_{args_r.strategy}!")
        end_critic()
    else:
        st.stop()

    shutil.make_archive('results', 'zip', "src/logs")

    st.divider()

    with open("results.zip", "rb") as fp:
        download_btn = st.download_button(
            label="Download Results zip",
            data=fp,
            file_name="results.zip",
            mime="application/zip"
        )
