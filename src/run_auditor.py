import json
import random
import argparse
import os
from tqdm import tqdm
from utils import dotdict
from stqdm import stqdm

import openai
from model import gpt, gpt_usage, OPENAI_API_KEY
from prompts import auditor_prompt, auditor_format_constrain
from prompts import topk_prompt1, topk_prompt2

completion_tokens = 0
prompt_tokens = 0

def remove_spaces(s):
    return ' '.join(s.split())

def prompt_wrap(prompt, format_constraint, code, topk):
    return prompt + code + format_constraint + topk_prompt1.format(topk=topk) + topk_prompt2

def auditor_response_parse(auditor_outputs):
    output_list = []
    for auditor_output in auditor_outputs:
        try:
            start_idx = auditor_output.find("{")
            end_idx = auditor_output.rfind("}")
            data = json.loads(auditor_output[start_idx: end_idx+1])
        except:
            print("parsing json fail.")
            continue
        try:
            output_list += data["output_list"]
        except:
            print("No vulnerability detected")
            continue

    return output_list

def solve(args, code):

    bug_info_list = []
    auditor_input = prompt_wrap(auditor_prompt, auditor_format_constrain, code, args.topk)

    try:
        auditor_outputs = gpt(auditor_input, model=args.backend, temperature=args.temperature, n=args.num_auditor)
        bug_info_list = auditor_response_parse(auditor_outputs)
    except Exception as e:
        print(e)

    return bug_info_list

def run(args):

    openai.api_key = OPENAI_API_KEY

    with open("data/CVE_label/CVE2description.json", "r") as f:
        CVE2description = json.load(f)
    with open("data/CVE_label/CVE2label.json", "r") as f:
        CVE2label = json.load(f)

    # log output file
    log_dir = f"./src/logs/auditor_{args.backend}_{args.temperature}_top{args.topk}_{args.num_auditor}"

    for CVE_index, label in stqdm(CVE2label.items()):

        all_bug_info_list = []
        description = CVE2description[CVE_index]
        file_name = "-".join(CVE_index.split("-")[1:]) + ".sol"

        with open("data/CVE_clean/" + file_name, "r") as f:
            code = f.read()
        # remove space
        code = remove_spaces(code)

        # auditing
        bug_info_list = solve(args, code)

        if len(bug_info_list) == 0: #Sometimes the query fails because the model does not strictly follow the format
            print("{index} failed".format(index=CVE_index))
            continue

        for info in bug_info_list:
            info.update({"file_name": file_name, "label": label, "description": description})
            all_bug_info_list.append(info)

        file = os.path.join(log_dir, CVE_index+".json")
        os.makedirs(os.path.dirname(file), exist_ok=True)

        with open(file, 'w') as f:
            json.dump(all_bug_info_list, f, indent=4)

def parse_args():
    args = argparse.ArgumentParser()
    args.add_argument('--backend', type=str, choices=['gpt-3.5-turbo','gpt-4', 'gpt-4-turbo-preview'], default='gpt-4-turbo-preview')
    args.add_argument('--temperature', type=float, default=0.7)
    args.add_argument('--dataset', type=str, default="CVE")
    args.add_argument('--topk', type=int, default=5) # the topk per each auditor
    args.add_argument('--num_auditor', type=int, default=1)

    args = args.parse_args()
    return args

if __name__ == '__main__':

    args = parse_args()
    print(args)
    run(args)

def mainfnc(args=dotdict):
    # args = parse_args()
    print(args)
    run(args)