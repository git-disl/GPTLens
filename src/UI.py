from openai import OpenAI
import streamlit as st
import os

with st.sidebar:
    openai_api_key = os.environ.get('OPENAI_API') #"Enter your openai API key"
    "[Get an OpenAI API key](https://platform.openai.com/account/api-keys)"
    "[View the source code](https://github.com/streamlit/llm-examples/blob/main/Chatbot.py)"
    "[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/streamlit/llm-examples?quickstart=1)"

st.title("💬 GPTLens")
st.caption("🚀 Smart Contract Vulnerability Detection powered by OpenAI LLM")

# Store the initial value of widgets in session state
if "visibility" not in st.session_state:
    st.session_state.visibility = "visible"
    st.session_state.disabled = False

st.header("Auditor Step", divider=True)
st.divider()

col1, col2 = st.columns(2)

with col1:
    st.radio(
        "Set the GPT model 👉",
        key="model",
        options=["gpt-3.5-turbo", "gpt-4", "gpt-4-turbo-preview"],
        index=1
    )
    
    uploaded_files = st.file_uploader('Upload data folder as a zip',
    accept_multiple_files=True)

with col2:
    st.number_input(
        "Set the topk auditor responses 👉",
        key="topk",
        min_value=1,
        max_value=10,
        value=3,
        format="%d"
    )

    st.number_input(
        "Set the temperature 👉",
        key="temperature",
        min_value=0.0,
        max_value=1.0,
        value=0.7,
        format="%f"
    )

    st.number_input(
        "Set the num auditors 👉",
        key="num_auditors",
        min_value=1,
        max_value=10,
        value=1,
        format="%d"
    )