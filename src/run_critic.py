import json
import argparse
import os
import openai

from prompts import critic_zero_shot_prompt, critic_format_constrain
from model import gpt, OPENAI_API

completion_tokens = 0
prompt_tokens = 0

def critic_prompt_wrap(vul_info_list):
    '''
    [{'function': 'xxx', 'vulnerability': 'xx', 'reason': 'xx'}
     {'function': 'xxx', 'vulnerability': 'xx', 'reason': 'xx'}]
    '''
    index = 0
    vul_info_str = ''
    for vul_info in vul_info_list:
        function_name = vul_info["function_name"]
        function_code = vul_info["code"]
        vulnerability = vul_info["vulnerability"]
        reason = vul_info["reason"]
        vul_info_str = vul_info_str + "function_name: " + function_name + "\n" + "code: " + function_code + "\n" + "vulnerability" + ": " + vulnerability + "\n" + "reason: " + reason + "\n------------------\n"
        index += 1

    return critic_zero_shot_prompt + vul_info_str + critic_format_constrain # notice this is zero shot prompt

def critic_response_parse(critic_outputs):
    output_list = []
    for critic_output in critic_outputs:
        try:
            data = json.loads(critic_output)
            output_list += data["output_list"]
        except:
            continue
    return output_list

def run(args):

    openai.api_key = OPENAI_API
    critic_dir = os.path.join("logs", args.auditor_dir, f"critic_{args.backend}_{args.temperature}_{args.num_critic}")

    for filename in os.listdir(os.path.join("logs", args.auditor_dir)):
        if not filename.endswith("json"):
            continue
        # if filename not in ("CVE-2018-10666.json"):
        #     continue
        filepath = os.path.join("logs", args.auditor_dir, filename)
        with open(filepath, "r") as f:
            auditor_output_list = json.load(f)

        critic_bug_info_final_list = []
        vul_info_str = ''
        for i in range(len(auditor_output_list)):
            bug_info = auditor_output_list[i]
            function_name = bug_info["function_name"]
            function_code = bug_info["code"]
            vulnerability = bug_info["vulnerability"]
            reason = bug_info["reason"]
            vul_info_str = vul_info_str + "function_name: " + function_name + "\n" + "code: " + function_code + "\n" + "vulnerability" + ": " + vulnerability + "\n" + "reason: " + reason + "\n------------------\n"

        # do wrap
        critic_input = critic_zero_shot_prompt + vul_info_str + critic_format_constrain  # notice this is zero shot prompt
        critic_outputs = gpt(critic_input, model=args.backend, temperature=args.temperature, n=args.num_critic)
        critic_bug_info_list = critic_response_parse(critic_outputs)

        for i in range(len(critic_bug_info_list)):
            function_name = auditor_output_list[i]["function_name"]
            label = auditor_output_list[i]["label"]
            code = auditor_output_list[i]["code"]
            file_name = auditor_output_list[i]["file_name"]
            description = auditor_output_list[i]["description"]
            reason = auditor_output_list[i]["reason"]

            critic_bug_info = critic_bug_info_list[i]
            critic_bug_info.update(
                {"reason": reason, "code": code, "label": label, "file_name": file_name, "description": description})

            critic_bug_info_final_list.append(critic_bug_info)

        filepath = os.path.join(critic_dir, filename)
        # dump the file
        os.makedirs(os.path.dirname(filepath), exist_ok=True)

        with open(filepath, 'w') as f:
            json.dump(critic_bug_info_final_list, f, indent=4)

    print("Done")


def parse_args():
    args = argparse.ArgumentParser()
    args.add_argument('--backend', type=str, choices=['gpt-3.5-turbo','gpt-4'], default='gpt-4')
    args.add_argument('--temperature', type=float, default=0)
    args.add_argument('--dataset', type=str, choices=['CVE'], default="CVE")
    args.add_argument('--auditor_dir', type=str, default="auditor_gpt-4_0.7_top3_1") #The auditor output directory
    args.add_argument('--num_critic', type=int, default=1)
    args.add_argument('--shot', type=str, choices=["zero", "few"], default="zero")

    args = args.parse_args()

    return args


if __name__ == '__main__':

    args = parse_args()
    print(args)
    run(args)
