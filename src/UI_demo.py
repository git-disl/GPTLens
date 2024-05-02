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
import base64
from pathlib import Path

os.environ['DISPLAY'] = ':0'

# Store the initial value of widgets in session state
if "visibility" not in st.session_state:
    st.session_state.visibility = "visible"
    st.session_state.disabled = False

if "start_preprocess" not in st.session_state:
    st.session_state.start_preprocess = False

if "start_critic" not in st.session_state:
    st.session_state.start_critic = False

if "start_auditor" not in st.session_state:
    st.session_state.start_auditor = False

if "start_ranking" not in st.session_state:
    st.session_state.start_ranking = False

if "section_active_preprocess" not in st.session_state:
    st.session_state.section_active_preprocess = True

if "section_active_auditor" not in st.session_state:
    st.session_state.section_active_auditor = False

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

def start_preprocess():
    st.session_state.start_preprocess = True
def end_preprocess():
    st.session_state.end_preprocess = False


def start_auditor():
    st.session_state.start_auditor = True
def end_auditor():
    st.session_state.start_auditor = False

def start_critic():
    st.session_state.start_critic = True
def end_critic():
    st.session_state.start_critic = False

def start_ranking():
    st.session_state.start_ranking = True
def end_ranking():
    st.session_state.start_ranking = False

openai_api_key = "xyz"

with st.sidebar:
    # openai_api_key = st.text_input("OpenAI API Key", key="chatbot_api_key", type="password")
    # "[Get an OpenAI API key (not needed for demo)](https://platform.openai.com/account/api-keys)"
    # "[View the source code](https://github.com/sciencepal/GPTLens/blob/aditya-test/src/UI.py)"
    # "[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/sciencepal/GPTLens?quickstart=1)"
    # st.divider()
    # if st.button("Reset App"):
    #     st.session_state.section_active_critic = False
    #     st.session_state.section_active_ranking = False
    #     st.session_state.section_active_auditor = False
    #     end_critic()
    #     end_ranking()
    #     end_auditor()
    bin_file = "src/CS8903_Aditya_PAL_GPTLens_Demo.pdf"
    with open(bin_file, 'rb') as f:
        data = f.read()
    st.download_button(label="Download GPTLens Demo PPT", data=data, file_name=bin_file, mime='application/pdf',)


    # st.link_button("Demo of GPTLens", "file:///CS8903_Aditya_PAL_GPTLens_Demo.pdf")
    # return href
        # streamlit_js_eval(js_expressions="parent.window.location.reload()")


st.title("💬 GPTLens Demo")
st.caption("🚀 Smart Contract Vulnerability Detection powered by OpenAI LLM")


if not openai_api_key:
    st.warning("In GPTlens, you must enter OpenAI API key to continue. Not needed for this demo")
    # st.stop()
else:
    os.environ["OPENAI_API_KEY"] = openai_api_key

st.info("Note that this demo uses only dummy data")


with open("data_sample/CVE/2018-13071.sol") as f:
    raw1 = f.read()
with open("data_sample/CVE/2018-13072.sol") as f:
    raw2 = f.read()
with open("data_sample/CVE/2018-13073.sol") as f:
    raw3 = f.read()
with open("data_sample/CVE/2018-13074.sol") as f:
    raw4 = f.read()

with open("data_sample/CVE_clean/2018-13071.sol") as f:
    clean1 = f.read()
with open("data_sample/CVE_clean/2018-13072.sol") as f:
    clean2 = f.read()
with open("data_sample/CVE_clean/2018-13073.sol") as f:
    clean3 = f.read()
with open("data_sample/CVE_clean/2018-13074.sol") as f:
    clean4 = f.read()

with open("data_sample/prompts.py") as f:
    prompt = f.read()


with open("results/auditor_gpt-4-turbo-preview_0.7_top3_1/2018-13071.json") as f:
    audit1 = f.read()
with open("results/auditor_gpt-4-turbo-preview_0.7_top3_1/2018-13072.json") as f:
    audit2 = f.read()
with open("results/auditor_gpt-4-turbo-preview_0.7_top3_1/2018-13073.json") as f:
    audit3 = f.read()
with open("results/auditor_gpt-4-turbo-preview_0.7_top3_1/2018-13074.json") as f:
    audit4 = f.read()


with open("results/auditor_gpt-4-turbo-preview_0.7_top3_1/critic_gpt-4-turbo-preview_0.0_1_few/2018-13071.json") as f:
    critic1 = f.read()
with open("results/auditor_gpt-4-turbo-preview_0.7_top3_1/critic_gpt-4-turbo-preview_0.0_1_few/2018-13072.json") as f:
    critic2 = f.read()
with open("results/auditor_gpt-4-turbo-preview_0.7_top3_1/critic_gpt-4-turbo-preview_0.0_1_few/2018-13073.json") as f:
    critic3 = f.read()
with open("results/auditor_gpt-4-turbo-preview_0.7_top3_1/critic_gpt-4-turbo-preview_0.0_1_few/2018-13074.json") as f:
    critic4 = f.read()


with open("results/auditor_gpt-4-turbo-preview_0.7_top3_1/critic_gpt-4-turbo-preview_0.0_1_few/ranker_default/2018-13071.json") as f:
    ranker1 = f.read()
with open("results/auditor_gpt-4-turbo-preview_0.7_top3_1/critic_gpt-4-turbo-preview_0.0_1_few/ranker_default/2018-13072.json") as f:
    ranker2 = f.read()
with open("results/auditor_gpt-4-turbo-preview_0.7_top3_1/critic_gpt-4-turbo-preview_0.0_1_few/ranker_default/2018-13073.json") as f:
    ranker3 = f.read()
with open("results/auditor_gpt-4-turbo-preview_0.7_top3_1/critic_gpt-4-turbo-preview_0.0_1_few/ranker_default/2018-13074.json") as f:
    ranker4 = f.read()


# if st.session_state.section_active_preprocess:

st.header("1. Preprocessing Step", divider=True)

tab4, tab3, tab2, tab1 = st.tabs(["File 1", "File 2", "File 3", "File 4"])

with tab1:
    with st.container(height=400):
        st.code(raw1, language='solidity')

with tab2:
    with st.container(height=400):
        st.code(raw2, language='solidity')

with tab3:
    with st.container(height=400):
        st.code(raw3, language='solidity')

with tab4:
    with st.container(height=400):
        st.code(raw4, language='solidity')

# preprocess_button = st.button("Start Preprocessing", key="preprocess", on_click=start_auditor)


# if st.session_state.start_auditor:

st.subheader("Result 1.1 - Processed Files", divider=True)

tab4, tab3, tab2, tab1 = st.tabs(["File 1", "File 2", "File 3", "File 4"])

with tab1:
    with st.container(height=400):
        st.code(clean1, language='solidity')

with tab2:
    with st.container(height=400):
        st.code(clean2, language='solidity')

with tab3:
    with st.container(height=400):
        st.code(clean3, language='solidity')

with tab4:
    with st.container(height=400):
        st.code(clean4, language='solidity')

st.divider()

st.header("2. Auditor Step", divider=True)

col1, col2 = st.columns(2)

with col1:
    model = st.radio(
        "Set the GPT model 👉",
        key="model",
        options=["gpt-3.5-turbo", "gpt-4", "gpt-4-turbo-preview"],
        index=2
    )

    topk =  st.number_input(
        "Set the topk auditor responses 👉",
        key="topk",
        min_value=1,
        max_value=10,
        value=3,
        format="%d"
    )
    
with col2:

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

st.subheader("Prompt File")
with st.container(height=400):
    st.code(prompt, language='python')


st.subheader("Result 2.1 - Auditor Results", divider=True)

tab4, tab3, tab2, tab1 = st.tabs(["File 1", "File 2", "File 3", "File 4"])

with tab1:
    with st.container(height=400):
        st.code(audit1, language='json')

with tab2:
    with st.container(height=400):
        st.code(audit2, language='json')

with tab3:
    with st.container(height=400):
        st.code(audit3, language='json')

with tab4:
    with st.container(height=400):
        st.code(audit4, language='json')

st.divider()



st.header("3. Critic Step", divider=True)

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
        value=f"temporary_dir/path/to/data"
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


st.subheader("Result 3.1 - Critic Results", divider=True)

tab4, tab3, tab2, tab1 = st.tabs(["File 1", "File 2", "File 3", "File 4"])

with tab1:
    with st.container(height=400):
        st.code(critic1, language='json')

with tab2:
    with st.container(height=400):
        st.code(critic2, language='json')

with tab3:
    with st.container(height=400):
        st.code(critic3, language='json')

with tab4:
    with st.container(height=400):
        st.code(critic4, language='json')

st.divider()








st.header("4. Ranking Step", divider=True)

col1, col2 = st.columns(2)

args = st.session_state.args
args_c = st.session_state.args_c

with col1:
    
    auditor_dir_r = st.text_input(
        "Auditor Dir location",
        value=f"temporary_dir/path/to/data"
    )

    critic_dir_r = st.text_input(
        "Critic Directory location",
        value=f"temporary_dir/path/to/data"
    )

with col2:

    strategy_r = st.radio(
        "Set the strategy (default/custom) 👉",
        key="strategy_r",
        options=["default", "custom"],
        index=0
    )


st.subheader("Result 4.1 - Ranking Results", divider=True)

tab4, tab3, tab2, tab1 = st.tabs(["File 1", "File 2", "File 3", "File 4"])

with tab1:
    with st.container(height=400):
        st.code(ranker1, language='json')

with tab2:
    with st.container(height=400):
        st.code(ranker2, language='json')

with tab3:
    with st.container(height=400):
        st.code(ranker3, language='json')

with tab4:
    with st.container(height=400):
        st.code(ranker4, language='json')

st.divider()