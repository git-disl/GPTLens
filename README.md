# GPTLens

This is the repo for the code and datasets used in the paper [Large Language Model-Powered Smart Contract Vulnerability Detection: New Perspectives](https://arxiv.org/pdf/2310.01152.pdf), accepted by the IEEE Trust, Privacy and Security (TPS) conference 2023.

If you find this repository useful, please give us a star! Thank you: )

If you wish to run your own dataset, please switch to the "release" branch:
```sh
git checkout release
```

## Getting Start

### Step 0: Set up your GPT-4 API

Get GPT-4 API from https://platform.openai.com/account/api-keys

Replace OPENAI_API_KEY = "Enter your openai API key" in src/model.py (line 4) with your API key.

Set up Python environment by importing environment.yml as a Conda env.

### Step 1: Run Auditor

Stay on GPTLens base folder

```sh
python src/run_auditor.py --backend=gpt-4 --temperature=0.7 --topk=3 --num_auditor=1
```

| Parameter       | Description                                                     |
|-----------------|-----------------------------------------------------------------|
| `backend`       | The version of GPT                                              |
| `temperature`   | The hyper-parameter that controls the randomness of generation. |
| `topk`          | Identify k vulnerabilities per each auditor                     |
| `num_auditor`   | The total number of independent auditors.                       |


### Step 2: Run Critic

```sh
python src/run_critic.py --backend=gpt-4 --temperature=0 --auditor_dir="auditor_gpt-4_0.7_top3_1" --num_critic=1 --shot=few
```
| Parameter     | Description                                                     |
|---------------|-----------------------------------------------------------------|
| `backend`     | The version of GPT                                              |
| `temperature` | The hyper-parameter that controls the randomness of generation. |
| `auditor_dir` | The directory of logs outputted by the auditor.                 |
| `num_critic`  | The total number of independent critics.                        |
| `shot`        | Whether few shot or zero shot prompt.                           |



### Step 3: Run Ranker

```sh
python src/run_rank.py --auditor_dir="auditor_gpt-4_0.7_top3_1" --critic_dir="critic_gpt-4_0_1_few" --strategy="default"
```
| Parameter     | Description                                     |
|---------------|-------------------------------------------------|
| `auditor_dir` | The directory of logs outputted by the auditor. |
| `critic_dir`  | The directory of logs outputted by the critic.  |
| `strategy`    | The strategy for generating the final score.    |


Some updates: 

**09/28**: We observed that the outputs of auditors can drift largely at different time periods. 
For instance, GPT-4 could easily identify the vulnerability in the CVE-2018-19830.sol at Sep. 16 but had difficulty detecting it at Sep. 28.
```sh
    {
        "function_name": "UBSexToken",
        "vulnerability": "Unexpected Behaviour",
        "criticism": "The reasoning is correct. The function name does not match the contract name, which means it is not the constructor and can be called by anyone at any time. This can lead to the totalSupply and owner of the token being reset, which is a serious vulnerability.",
        "correctness": 9,
        "severity": 9,
        "profitability": 9,
        "reason": "The function name does not match the contract name. This indicates that this function is intended to be the constructor, but it is not. This means that anyone can call the function at any time and reset the totalSupply and owner of the token.",
        "code": "function UBSexToken() {\n    owner = msg.sender;\n    totalSupply = 1.9 * 10 ** 26;\n    balances[owner] = totalSupply;\n}",
        "label": "Access Control",
        "file_name": "2018-19830.sol",
        "description": "The UBSexToken() function of a smart contract implementation for Business Alliance Financial Circle (BAFC), an tradable Ethereum ERC20 token, allows attackers to change the owner of the contract, because the function is public (by default) and does not check the caller's identity."
    },
```
We uploaded a set of results that we obtained on Sep. 28 using GPT-4 with 1 auditor, 1 critic and 3 outputs per each contract (see src/logs/auditor_gpt-4_0.7_top3_1/critic_gpt-4_0_1_zero_0928). 
The composite score less than 5 can be deemed as not being a vulnerability.

**10/26**: We observed that the output of critic can also be different (-.-) at different time periods, even with the same input and the temperature set to 0 (deterministic generation). This might be caused by the update of GPT-4 (?). To make scoring consistent, we added few shot examples for critic prompt. 
We uploaded a set of results of the critic with few-shot prompt that obtained on Oct. 26 using GPT-4 (see src/logs/auditor_gpt-4_0.7_top3_1/critic_gpt-4_0_1_few_1026).

This repo will be continuously updated to make generation more consistent and robust.

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

