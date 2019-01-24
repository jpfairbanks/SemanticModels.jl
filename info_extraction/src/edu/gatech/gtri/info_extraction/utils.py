import re
from functools import reduce

from bs4 import BeautifulSoup
from markdown import markdown
from pathlib import Path


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


def files_in_path_with_ext(f_path, ext):

    if not Path(f_path).is_dir():
        raise Exception("{} is not a valid directory.".format(f_path))

    try:
        return Path(f_path).rglob("*.{}".format(ext))

    except Exception as e:
        print("Unable to gather files at path: {}".format(f_path))
        print(e)


if __name__ == '__main__':
    chapters_path = "/Users/scott/Downloads/epicookbook-master/_chapters"
    out_path = "/Users/scott/Downloads/epicookbook-master/_chapters/output_txt"

    for path in files_in_path_with_ext(chapters_path, "md"):
        print(path)
        markdown_string = reduce(lambda x, y: x + y + "\n", open(path, "r").readlines(), "")
        text = markdown_to_text(markdown_string)
        open(out_path + "/" + path.parent.name + "__" + path.name + ".txt", "w").write(text)


