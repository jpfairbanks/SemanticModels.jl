import pprint
from collections import defaultdict
from functools import reduce
from bs4 import BeautifulSoup
from markdown import markdown
from pathlib import Path
import re


# gist:https://gist.github.com/lorey/eb15a7f3338f959a78cc3661fbc255fe
def markdown_to_text(markdown_string):
    """ Converts a markdown string to plaintext """

    # md -> html -> text since BeautifulSoup can extract text cleanly
    html = markdown(markdown_string)

    # remove code snippets
    html = re.sub(r'<pre>(.*?)</pre>', ' ', html)
    html = re.sub(r'<code>(.*?)</code >', ' ', html)

    # extract text
    soup = BeautifulSoup(html, "html.parser")
    text = ''.join(soup.findAll(text=True))

    return text


"""
Take an array of julia code lines and extract comments
"""


def julia_comment_extract(julia_code_lines):
    for line in julia_code_lines:
        processed_line = line.lstrip(" ")
        if processed_line.startswith("#"):
            yield line


"""
Take an array of julia code lines and extract parameters from julia function declarations
"""


def julia_param_extract(julia_code_lines):
    func_match = r'function\s*(.*?)\((.*?)\)'
    for line in julia_code_lines:
        match = re.search(func_match, line)
        if match:
            # grps = match.groups()
            func_name = match.group(1)
            params = match.group(2)
            func_pair = tuple((func_name, params.split(",")))
            yield func_pair


"""
Associate tokens from comments with parameters
    - comment_lines are textual comments extract from julia code
    - param_pairs are arrays of parameters extracted from each and every function signature along with function name
"""


def intersect_comments_params(comment_lines, param_pairs):
    associations = defaultdict(list)
    for param_pair in param_pairs:
        for comment in comment_lines:
            if param_pair[0] in comment:
                associations[param_pair[0]].append(comment)
            for param in param_pair[1]:
                if len(param) == 1:
                    param = " " + param + " "  # looks for single variable mentions with space around
                else:
                    param = param + " "  # look for variables and then a space (TODO: can enhance more as desired)
                if param in comment:
                    associations[param].append(comment)

    return associations


def files_in_path_with_ext(f_path, ext):
    if not Path(f_path).is_dir():
        raise Exception("{} is not a valid directory.".format(f_path))

    try:
        return Path(f_path).rglob("*.{}".format(ext))

    except Exception as e:
        print("Unable to gather files at path: {}".format(f_path))
        print(e)


def extract_markdown(o_path):
    for path in files_in_path_with_ext(chapters_path, "md"):
        print(path)
        markdown_string = reduce(lambda x, y: x + y + "\n", open(path, "r").readlines(), "")
        text = markdown_to_text(markdown_string)
        open(o_path + "/" + path.parent.name + "__" + path.name + ".txt", "w").write(text)


def extract_jl(jl_file):
    lines = list(open(jl_file, "r").readlines())
    comment_lines = julia_comment_extract(lines)
    param_pairs = julia_param_extract(lines)
    associations = intersect_comments_params(comment_lines, param_pairs)
    pprint.pprint(associations)


if __name__ == '__main__':

    # Note: epicookbook-master - has not been approved for commiting to repo
    # Change paths to your local files for now
    chapters_path = "./epicookbook-master/_chapters"
    out_path = "./epicookbook-master/_chapters/output_txt"

    # This is a relative path to test input file
    sample_jl_file = "../test/info_extraction/mdjl_extraction.py/expected_test_input/NHosts1Vector.jl"
    extract_jl(sample_jl_file)

    # Run extraction from Mardown
    # julia_param_extract(["function F(du,u,p,t)"])
