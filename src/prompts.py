
####### Basic Prompt ########
topk_prompt1 = '''Output {topk} most severe vulnerabilities.\n'''
topk_prompt2 = '''If no vulnerability is detected, you should only output in this json format {"output_list": []}.\n'''


####### Auditor Prompt #######
auditor_prompt = '''You are a smart contract auditor, identify and explain severe vulnerabilities in the provided smart contract. Make sure that they are exploitable in real world and beneficial to attackers. Provide each identified vulnerability with intermediate reasoning and its associated function. Remember, you must provide the entire function code and do not use "...". Make your reasoning comprehensive and detailed. Smart contract code:\n\n'''
auditor_format_constrain = '''\nYou should only output in below json format:
{
    "output_list": [
        {
            "function_name": "<function_name_1>",
            "code": "<original_function_code_1>",
            "vulnerability": "<short_vulnera_desc_1>",
            "reason": "<reason_1>"
        },
        {
            "function_name": "<function_name_2>",
            "code": "<original_function_code_2>",
            "vulnerability": "<short_vulnera_desc_2>",
            "reason": "<reason_2>"
        }
    ]
}
'''

####### Critic Prompt #######
critic_zero_shot_prompt = '''Below vulnerabilities and reasoning are likely contain mistakes. As a harsh vulnerability critic, your duty is to scrutinize the function and evaluate the correctness, severity and profitability of given vulnerabilities and explanation with corresponding scores ranging from 0 (lowest) to 9 (highest). Consider severity from the perspective of contract users and profitability from the perspective of an external attacker. Make your criticism and explanation comprehensive and detailed\n'''
critic_format_constrain = '''\nYou should only output in below json format:
{
    "output_list": [
        {
            "function_name": "<function_name_1>",
            "vulnerability": "<short_vulnera_desc_1>",
            "criticism_correctness": "<criticism for vulnerability and reasoning>",
            "correctness": <0~9>,
            "explain_severity": "<explanation for severity for contract users>"
            "severity": <0~9>,
            "explain_profitability": "<explanation for profitability for external attackers (not owner)>"
            "profitability": <0~9>,
        },
        {
            "function_name": "<function_name_2>",
            "vulnerability": "<short_vulnera_desc_2>",
            "criticism_correctness": "<criticism for vulnerability and reasoning>",
            "correctness": <0~9>,
            "explain_severity": "<explanation for severity for contract users>"
            "severity": <0~9>,
            "explain_profitability": "<explanation for profitability for external attackers (not owner)>"
            "profitability": <0~9>,
        }
    ]
}
'''


