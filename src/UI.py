import streamlit as st
import os
import zipfile
import run_auditor
import run_critic
import run_rank
import shutil
from utils import dotdict, clean_folder
# import pyautogui

os.environ['DISPLAY'] = ':0'

with st.sidebar:
    openai_api_key = st.text_input("OpenAI API Key", key="chatbot_api_key", type="password")
    "[Get an OpenAI API key](https://platform.openai.com/account/api-keys)"
    "[View the source code](https://github.com/streamlit/llm-examples/blob/main/Chatbot.py)"
    "[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/streamlit/llm-examples?quickstart=1)"

st.title("💬 GPTLens")
st.caption("🚀 Smart Contract Vulnerability Detection powered by OpenAI LLM")

if not openai_api_key:
    st.warning("Please add your OpenAI API key to continue.")
    st.stop()
else:
    os.environ["OPENAI_API"] = openai_api_key

# Store the initial value of widgets in session state
if "visibility" not in st.session_state:
    st.session_state.visibility = "visible"
    st.session_state.disabled = False

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
    
    uploaded_file = st.file_uploader('Upload data folder as a zip')

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

start_auditors = st.button("Start Auditors")

if start_auditors:
    if uploaded_file:
        args_dict = {
            'backend': model,
            'temperature': temperature,
            'dataset': "CVE",
            'topk': topk,
            'num_auditor': num_auditors
        }
        args = dotdict(args_dict)
        if os.path.exists("data"):
            clean_folder("data")
        if os.path.exists(f"src/logs/auditor_{args.backend}_{args.temperature}_top{args.topk}_{args.num_auditor}"):
            clean_folder(f"src/logs/auditor_{args.backend}_{args.temperature}_top{args.topk}_{args.num_auditor}")
        with open("data.zip", 'wb') as bin_file:
            bin_file.write(uploaded_file.read())
        with zipfile.ZipFile("data.zip", 'r') as zip_ref:
            zip_ref.extractall()
        st.write(f"Starting auditor code!")
        run_auditor.mainfnc(args)
        st.write(f"Audit files processed successfully to folder ./src/logs/auditor_{args.backend}_{args.temperature}_top{args.topk}_{args.num_auditor}!")
    else:
        st.warning("Please upload data zip.")
        st.stop()
else:
    st.stop()





st.header("Critic Step", divider=True)
st.divider()

col1, col2 = st.columns(2)

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

start_critics = st.button("Start Critics")

if start_critics:
    args_c_dict = {
        'backend': model_c,
        'temperature': temperature_c,
        'dataset': "CVE",
        'auditor_dir': auditor_dir_c,
        'num_critic': num_critic_c,
        'shot': shot_c
    }
    args_c = dotdict(args_c_dict)

    st.write(f"Starting critic code!")
    run_critic.mainfnc(args_c)
    st.write(f"Critic files processed successfully to folder ./src/logs/{args_c.auditor_dir}/critic_{args_c.backend}_{args_c.temperature}_{args_c.num_critic}_{args_c.shot}!")
else:
    st.stop()






st.header("Ranking Step", divider=True)
st.divider()

col1, col2 = st.columns(2)

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

start_ranking = st.button("Start Ranking")

if start_ranking:
    args_r_dict = {
        'auditor_dir': auditor_dir_r,
        'critic_dir': critic_dir_r,
        'strategy': strategy_r
    }
    args_r = dotdict(args_r_dict)
    st.write(f"Starting ranking code!")
    run_rank.mainfnc(args_r)
    st.write(f"Ranking files processed successfully to folder ./src/logs/{args_c.auditor_dir}/critic_{args_c.backend}_{args_c.temperature}_{args_c.num_critic}_{args_c.shot}/ranker_{args_r.strategy}!")
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

if st.button("Reset"):
    # pyautogui.hotkey("ctrl","F5")
    st.empty()
