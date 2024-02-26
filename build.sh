#!/bin/bash

rm -rf _site
mkdir -p _site

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "\e[1mBuilding projects...\e[0m\n"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for dir in */ ; do
    if [ -f "${dir}/build.sh" ]; then
        name=`basename $dir`
        echo "Building project in [${name}]"
        (cd "$dir" && /bin/bash build.sh)
        shot-scraper "./_site/${name}/index.html" --silent --retina --width 800 --height 800 --output "_site/images/${name}.png"
        echo "------------------------------------------------------------"
    fi
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "\e[1mConverting screenshots\e[0m\n"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for image in _site/images/*.png ; do
    name=$(basename $image .png)
    cwebp -q 100 -resize 800 800 -short $image -o _site/images/$name.webp
    rm -f $image
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "\e[1mBuilding index.html\e[0m\n"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"


CODE=$(cat <<-EOF
import glob, os
from jinja2 import Template

template = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>talks.karmi.cz</title>

  <style>
    body {
      color: #fff;
      background-color: black;
      font-family: monospace;
      padding: 5vh 5vw;
    }
    header h1 {
      opacity: 0.8;
    }
    section {
      display: inline-block;
    }
    section img {
      margin: 0 10px 10px 0;
      border-radius: 5px;
      opacity: 0.8;
    }
    section img:hover {
      opacity: 1;
    }
  </style>
</head>
<body>

  <header>
    <h1>talks.karmi.cz</h1>
  </header>

  {% for talk in talks %}
    <section>
        <a href="./{{talk}}/">
            <img src="./images/{{ talk }}.webp" width="400">
        </a>
    </section>
  {% endfor %}

</body>
</html>
'''
images = glob.glob('_site/images/*.webp')
talks = [os.path.splitext(os.path.basename(path))[0] for path in images]
html = Template(template).render({"talks":talks})
# print(html)
with open('_site/index.html', 'w') as file: file.write(html)
EOF)

python3.11 -c "${CODE}"

echo "open _site/index.html"
