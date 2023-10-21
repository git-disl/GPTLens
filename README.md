# GPTLens

This is the repo for the code and datasets used in the paper [Large Language Model-Powered Smart Contract Vulnerability Detection: New Perspectives](https://arxiv.org/pdf/2310.01152.pdf), accepted by the IEEE Trust, Privacy and Security (TPS) conference 2023.

If you find this repository useful, please give us a star! Thank you: )

## Getting Start

### Step 0: Set up your GPT-4 API

Get GPT-4 API from https://platform.openai.com/account/api-keys

Replace OPENAI_API = "Enter your openai API key" in src/model.py (line 4) with your API key.

### Step 1: Preprocess your own dataset

Add your dataset to the directory "GPTLens/data/xx"

remove the comments, empty lines and whitespace:

```sh
python pre_process.py --data_dir="../data/CVE" # replace CVE with your onw dataset
```

### Step 2: Run Auditor

```sh
python run_auditor.py --backend=gpt-4 --temperature=0.7 --topk=3 --num_auditor=1 --data_dir="../data/CVE_clean"
```

| Parameter      | Description                                                     |
|----------------|-----------------------------------------------------------------|
| `backend`      | The version of GPT                                              |
| `temperature`  | The hyper-parameter that controls the randomness of generation. |
| `topk`         | Identify k vulnerabilities per each auditor                     |
| `num_auditor`  | The total number of independent auditors.                       |
| `data_dir`     | The directory for storing preprocessed smart contracts.         |


### Step 3: Run Critic

```sh
python run_critic.py --backend=gpt-4 --temperature=0 --auditor_dir="auditor_gpt-4_0.7_top3_1" --num_critic=1 
```
| Parameter      | Description                                                     |
|----------------|-----------------------------------------------------------------|
| `backend`      | The version of GPT                                              |
| `temperature`  | The hyper-parameter that controls the randomness of generation. |
| `auditor_dir`  | The directory of logs outputted by the auditor.                 |
| `num_critic`   | The total number of independent critics.                        |


### Step 4: Run Ranker

```sh
python run_ranker.py --auditor_dir="auditor_gpt-4_0.7_top3_1" --critic_dir="critic_gpt-4_0_1" --strategy="default"
```
| Parameter     | Description                                     |
|---------------|-------------------------------------------------|
| `auditor_dir` | The directory of logs outputted by the auditor. |
| `critic_dir`  | The directory of logs outputted by the critic.  |
| `strategy`    | The strategy for generating the final score.    |


Note: We observe that the output from auditors can drift largely between different runs due to randomness. We upload a set of results that we obtained on September 28 using GPT-4 with 1 auditor, 1 critic and 3 outputs per each contract (see src/logs).
The composite score less than 5 can be deemed as not being a vulnerability. 

-----
## Citation

```
@misc{hu2023large,
      title={Large Language Model-Powered Smart Contract Vulnerability Detection: New Perspectives}, 
      author={Sihao Hu and Tiansheng Huang and Fatih İlhan and Selim Furkan Tekin and Ling Liu},
      year={2023},
      eprint={2310.01152},
      archivePrefix={arXiv},
      primaryClass={cs.CR}
}
```

-----
## Q&A

If you have any questions, you can either open an issue or contact me (sihaohu@gatech.edu), and I will reply as soon as I see the issue or email.

