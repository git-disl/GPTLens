import gradio as gr
import os


os.environ['DISPLAY'] = ':0'

css = """"""

with gr.Blocks(css=css) as ui:
    gr.Image("src/images/header.png", min_width=1500, height=80, show_download_button=False, show_label=False)
    gr.HTML(value="<h2>Harnessing Large Language Models to Secure Smart Contracts</h2>")
    gr.HTML(value="<font size=\"+0.5\"><p>Smart contracts are revolutionizing many industries, but vulnerabilities in their code can lead to significant financial losses. The <a href=\"https://arxiv.org/pdf/2310.01152.pdf\">paper</a> explores how Large Language Models (LLMs) can be used to detect these vulnerabilities in smart contracts. In this static webpage, we discuss the same briefly, and link to a GUI that can help visualise the flow in a much lucid way along with a report that entends the ideas presented in the paper. To continue, LLMs are a type of artificial intelligence that can process and understand massive amounts of text data.  The authors propose a new approach,  GPTLENS, that leverages LLMs to identify potential weaknesses in smart contract code.</p><font>")
    gr.HTML(value="<font size=\"+0.5\"><p>The main thing to keep in mind in order to successfully discover as many vulnerabilities as possible is to maximize the true positives and minimize the false positives. To tackle this imbalance, GPTLens proposes an adverserial model that consists of two stages - Generative and Discriminative. In the mentioned stages, the GPT, most commonly GPT 4, plays both the roles of an AUDITOR and a CRITIC. The goal of AUDITOR is to yield a broad spectrum of vulnerabilities with the hope of encompassing the correct answer, whereas the goal of CRITIC that evaluates the validity of identified vulnerabilities is to minimize the number of false positives.  Compared to exisitng models in the market, GPTLens has some key advantages, some of the key benefits of using LLMs for smart contract vulnerability detection are as below :</p><font>")
    gr.HTML(value="<font size=\"+0.5\"><ul><li><em>Generality:</em> Unlike traditional tools that target specific vulnerabilities, LLMs can potentially detect a wider range of issues, including those previously unknown.</li><li><em>Interpretability:</em> LLMs can not only identify vulnerabilities but also explain their reasoning, providing valuable insights to developers.</li><li><em>Efficiency: </em>LLM services provide efficient online inference, making LLM-powered methods output results much faster than many traditional methods </li></ul><font>")
    gr.HTML(value="<font size=\"+0.5\">One can imagine how powerful this model looks in theory but there are some challenges to consider:<font>")
    gr.HTML(value="<font size=\"+0.5\"><ul><li><em>False Positives:</em> LLMs may generate a large number of incorrect findings, requiring human effort to sort through them.</li><li><em>False Negatives:</em> Not all vulnerabilities may be detected, especially complex ones or those missed due to randomness in the LLM's output.</li></ul><font>")
    gr.HTML(value="<font size=\"+0.5\"><p>This two-step adversial detection framework has but one main goal in place - \"to present a simple, effective, and entirely LLM-driven methodology to shed light on the design of LLM-powered approaches\". The two-step model helps to mitigate the trade-off between finding more vulnerabilities and reducing false positives. The primary goal of the generation stage is to enhance the likelihood of true vulnerabilities being identified. To achieve that, we ask an LLM to play the role of multiple auditor agents, and each auditor generates answers (vulnerability and the reasoning) with high randomness, even though it could lead to a plethora of incorrect answers. To realize this, we prompt the LLM to play the role of a critic agent, which evaluates each identified vulnerability on a set of criteria, such as correctness, severity, and profitability, and assigns corresponding scores. The <a href=\"https://arxiv.org/pdf/2310.01152.pdf\">paper</a> demonstrates that GPTLENS can outperform traditional methods in identifying vulnerabilities within smart contracts. Overall, this research suggests that LLMs have the potential to become a powerful tool for safeguarding smart contracts.</p><font>")
    gr.HTML(value="<font size=\"+0.5\"><p>Below is an example flow of how the model works :- </p><font>")
    gr.Image("src/images/model.png", width=700, show_download_button=False, show_label=False)
    gr.HTML(value="<font size=\"+0.5\"><p>Below is an example prompt both from Auditor as well as Critic side :- </p><font>")
    with gr.Row():
        with gr.Column(scale=1, min_width=500):
            gr.Image("src/images/auditor_prompt.png", width=500, show_download_button=False, show_label=False)
        with gr.Column(scale=1, min_width=500):
            gr.Image("src/images/critic_prompt.png", width=500, show_download_button=False, show_label=False)
    gr.HTML(value="<font size=\"+0.5\"><p>Below is an example response both from Auditor as well as Critic side :- </p><font>")
    with gr.Row():
        with gr.Column(scale=1, min_width=500):
            gr.Image("src/images/auditor_reasoning.png", width=500, show_download_button=False, show_label=False)
        with gr.Column(scale=1, min_width=500):
            gr.Image("src/images/criticism.png", width=500, show_download_button=False, show_label=False)
    gr.HTML(value="<font size=\"+0.5\"><p>There is an additional stage called Ranking/Discrimination. As we know, the role of a critic is to filter out the correct results from a myriad of false positives. To ascertain what is the best, we consider three distinct factors: correctness, severity and profitability, because although some false positives may be correct, they might possess a diminished level of severity or may not be profitable for attackers. The role of the Ranker is to rank all vulnerabilities descendingly based on these scores and choose the top-k vulnerabilities from the list as the output.</p><font>")

    with gr.Row():
        with gr.Column(scale=1, min_width=500):
            gr.Button(value="You can browse the GUI by clicking here", link="https://e5f2d87bf4047aa563.gradio.live", variant="primary")
        with gr.Column(scale=1, min_width=500):
            gr.Button("You can view the explainability report by clicking here", link="https://docs.google.com/document/d/e/2PACX-1vQMRO7rtLrdXchyP1TXOH8jJ0jGS1lw-OcAvmYGDNFve1plgXjm7bBGKaWrlxBC6XdIGpvku3ArNavO/pub", variant="primary")

    gr.Markdown("# Meet the Team")

    with gr.Row():
        with gr.Column(scale=1, min_width=333):
            gr.Image("src/images/developer.png", min_width=300, height=300, show_download_button=False, show_label=False, scale=1)
            gr.Markdown("### GUI Developer - Aishwarya Solanki")
            gr.Button(value="GitHub Profile", link="https://github.com/AishwaryaSolanki")
            gr.Button(value="Related Work", link="https://codepen.io/pennywise97")
        with gr.Column(scale=1, min_width=333):
            gr.Image("src/images/author.png", min_width=300, height=300, show_download_button=False, show_label=False, scale=1)
            gr.Markdown("### Paper Author and Creator - Sihao Hu")
            gr.Button(value="GitHub Page", link="https://bayi-hu.github.io")
            gr.Button(value="Published Paper", link="https://arxiv.org/pdf/2310.01152.pdf")
        with gr.Column(scale=1, min_width=333):
            gr.Image("src/images/professor.png", min_width=300, height=300, show_download_button=False, show_label=False, scale=1)
            gr.Markdown("### Advisor Professor - Ling Liu")
            gr.Button(value="Team GitHub Profile", link="https://github.com/git-disl/GPTLens")
            gr.Button(value="Profile", link="https://www.cc.gatech.edu/people/ling-liu")

    gr.Markdown("### School of Computer Science, Georgia Institute of Technology, Atlanta, GA 30332, United States")
        
ui.launch()