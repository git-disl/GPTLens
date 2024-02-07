import json
import argparse
import os
from stqdm import stqdm
from utils import dotdict


def rank_by_score(json_list):
    return sorted(json_list, key=lambda x: x["final_score"], reverse=True)

def run(args):
    # output file
    ranker_dir = f"ranker_{args.strategy}"

    for filename in stqdm(os.listdir(f"src/logs/{args.auditor_dir}/{args.critic_dir}")):
        if not filename.endswith("json"):
            continue
        filepath = f"src/logs/{args.auditor_dir}/{args.critic_dir}/{filename}"
        with open(filepath, "r") as f:
            critic_output_list = json.load(f)

        for i in range(len(critic_output_list)):
            bug_info = critic_output_list[i]
            correctness = float(bug_info["correctness"])
            severity = float(bug_info["severity"])
            profitability = float(bug_info["profitability"])

            # overall score
            if args.strategy == "default":
                # naive weighted function
                final_score = 0.5 * correctness + 0.25 * severity + 0.25 * profitability

            elif args.strategy == "customize":
                # TODO: add your scoring function
                pass
            else:
                raise Exception("Please choose correct strategy for scoring...")

            bug_info.update({"final_score": final_score})

        # Rank based on scores
        ranker_output_list = rank_by_score(critic_output_list)
        filepath = f"src/logs/{args.auditor_dir}/{args.critic_dir}/{ranker_dir}/{filename}"
        # dump the file
        os.makedirs(os.path.dirname(filepath), exist_ok=True)

        with open(filepath, 'w') as f:
            json.dump(ranker_output_list, f, indent=4)

    print("Ranking finished...")

def parse_args():
    args = argparse.ArgumentParser()
    args.add_argument('--dataset', type=str, choices=['CVE'], default="CVE")
    args.add_argument('--auditor_dir', type=str, default="auditor_gpt-4_0.7_top3_1") #The auditor output directory
    args.add_argument('--critic_dir', type=str, default="critic_gpt-4_0_1_few_1026") #The critic output directory
    args.add_argument('--strategy', type=str, default="default", choices=["default", "customize"])

    args = args.parse_args()
    return args

if __name__ == '__main__':
    args = parse_args()
    print(args)
    run(args)


def mainfnc(args=dotdict):
    # args = parse_args()
    # print(args)
    run(args)