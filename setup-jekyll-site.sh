#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error on line $LINENO" >&2; exit 1' ERR

echo "🔨 Bootstrapping Tensor Framework Jekyll site…"

# --- NEW: auto-init git if needed ---
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "⚙️  No git repo detected—initializing..."
  git init
fi

# 0. Ensure on `main`
if git rev-parse --verify main >/dev/null 2>&1; then
  git checkout main
elif git rev-parse --verify master >/dev/null 2>&1; then
  git branch -m master main
  git checkout main
else
  git checkout -b main
fi

# 1. Commit any existing changes before we start
if [ -n "$(git status --porcelain)" ]; then
  git add .
  git commit -m "chore: preserve initial site structure before scaffolding"
  echo "✅ Initial state committed."
else
  echo "ℹ️ No uncommitted changes to preserve."
fi

# 2. Seed root‐level files
echo "📄 Creating .gitignore, Gemfile, and README.md…"
cat > .gitignore << 'EOF'
# Jekyll build output
_site/
.jekyll-cache/
.sass-cache/
.jekyll-metadata

# Bundler
/.bundle
/vendor/bundle

# OS files
.DS_Store

# Keep IDE configs
.vscode/
.devcontainer/
EOF

cat > Gemfile << 'EOF'
source "https://rubygems.org"
gem "github-pages", group: :jekyll_plugins
EOF

cat > README.md << 'EOF'
# Tensor Framework Site

This repo contains the **source** for the Tensor Framework website, built with Jekyll and GitHub Pages.

## Quickstart

1. Install dependencies:
   ```bash
   bundle install
   ```
2. Serve locally:
   ```bash
   bundle exec jekyll serve --source site --livereload
   ```
3. Build for production:
   ```bash
   bundle exec jekyll build --source site --destination site/_site
   ```
EOF

# 3. Scaffold site/
echo "📁 Scaffolding under site/…"
cd site

# 3a. Clean out everything except assets/img, _schemas, _graphs
shopt -s extglob
rm -rf !(assets|_schemas|_graphs)
shopt -u extglob

# 3b. Recreate Jekyll structure
mkdir -p _includes _layouts _sass assets/css pages studio

# 4. Write site/_config.yml
echo "📄 Writing site/_config.yml…"
cat > _config.yml << 'EOF'
title: "Tensor Framework"
markdown: kramdown
sass:
  style: compressed

collections:
  graphs:
    output: true
    permalink: /graphs/:path/
  schemas:
    output: true
    permalink: /schemas/:path/

navigation:
  - title: "About"
    url: "/pages/about.html"
  - title: "Docs"
    url: "/pages/docs.html"
  - title: "Schemas"
    url: "/schemas/"
  - title: "Graphs"
    url: "/graphs/"
  - title: "Extensions"
    url: "/pages/extensions.html"
  - title: "Studio"
    url: "/pages/studio.html"
  - title: "GitHub"
    url: "https://github.com/tensor-standards-consortium/tensor-framework"
EOF

# 5. _includes
echo "📄 Generating _includes…"
cat > _includes/head.html << 'EOF'
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{{ page.title | default: site.title }}</title>
  <link rel="stylesheet" href="{{ '/assets/css/main.css' | relative_url }}">
</head>
EOF

cat > _includes/header.html << 'EOF'
<header class="bg-transparent absolute w-full z-10">
  <div class="container mx-auto px-4 py-6 flex justify-between items-center">
    <a href="/" class="flex items-center space-x-2">
      <img src="{{ '/assets/img/logo-tensor-icon.png' | relative_url }}" alt="TENSOR Logo" class="h-8">
      <span class="font-bold text-white text-xl">TENSOR</span>
    </a>
    <nav>
      <ul class="flex space-x-4 text-white">
        {% for item in site.navigation %}
          <li><a href="{{ item.url | relative_url }}" class="hover:underline">{{ item.title }}</a></li>
        {% endfor %}
      </ul>
    </nav>
  </div>
</header>
EOF

cat > _includes/footer.html << 'EOF'
<footer class="bg-[#141E30] text-gray-400 py-8">
  <div class="container mx-auto px-4 flex flex-col md:flex-row justify-between items-center">
    <p class="text-sm">© {{ "now" | date: "%Y" }} Tensor Standards Consortium</p>
    <nav class="mt-4 md:mt-0">
      <ul class="flex space-x-4 text-sm">
        {% for item in site.navigation limit:5 offset:1 %}
          <li><a href="{{ item.url | relative_url }}" class="hover:text-white">{{ item.title }}</a></li>
        {% endfor %}
      </ul>
    </nav>
  </div>
</footer>
EOF

# 6. _layouts
echo "📄 Generating _layouts…"
cat > _layouts/default.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
  {% include head.html %}
  <body class="bg-white text-gray-900">
    {% include header.html %}
    <main>
      {{ content }}
    </main>
    {% include footer.html %}
  </body>
</html>
EOF

cat > _layouts/home.html << 'EOF'
---
layout: default
---
<section class="relative overflow-hidden">
  <div class="hero-bg absolute inset-0 bg-cover bg-center"
       style="background-image:url('{{ '/assets/img/mesh.png' | relative_url }}')">
  </div>
  <div class="relative container mx-auto px-4 py-24 text-center text-white">
    <h1 class="text-5xl font-extrabold mb-4">TENSOR Framework</h1>
    <p class="text-xl mb-6">
      Threat Evaluation &amp; Neutralization through Structured Organizational Resilience
    </p>
    <p class="max-w-xl mx-auto mb-8">
      A vendor-neutral, graph-driven SOC methodology — rapidly map, validate,
      and respond to threats with confidence.
    </p>
    <div class="flex justify-center items-center space-x-4">
      <a href="{{ '/docs/' | relative_url }}"
         class="px-6 py-3 bg-gradient-to-r from-[#43D9BE] to-[#2A76D1]
                rounded-lg font-medium">
        Explore the Framework
      </a>
      <span class="bg-white bg-opacity-20 text-white px-4 py-2 rounded">
        Version {{ site.time | date: '%Y%m%d' }}
      </span>
    </div>
  </div>
  <div class="absolute bottom-0 left-1/2 transform -translate-x-1/2
              w-[120%] h-64 bg-gradient-to-t from-[#43D9BE] to-transparent
              rounded-full">
  </div>
</section>

<section class="container mx-auto px-4 py-12 grid grid-cols-1 md:grid-cols-3 gap-8">
  {% assign features = "Extensible|Layer extension graphs without altering the core.;Standardized|Preserve structured integrity and clear repo layout.;Performant|Lightweight graphs render quickly in any browser." | split:';' %}
  {% for f in features %}
    {% assign parts = f | split:'|' %}
    <div class="feature-card p-6 rounded-lg bg-white bg-opacity-10">
      <h3 class="text-2xl font-semibold mb-2">{{ parts[0] }}</h3>
      <p>{{ parts[1] }}</p>
    </div>
  {% endfor %}
</section>
EOF

cat > _layouts/studio.html << 'EOF'
---
layout: default
---
<div class="container mx-auto p-6">
  <h1>{{ page.title }}</h1>
  <div id="graph-studio-app"></div>
  <script src="{{ '/studio/vendor/ajv.min.js' | relative_url }}"></script>
  <script src="{{ '/studio/vendor/cytoscape.min.js' | relative_url }}"></script>
  <script src="{{ '/studio/app.js' | relative_url }}"></script>
</div>
EOF

# 7. SCSS
echo "📄 Writing SCSS…"
cat > _sass/_variables.scss << 'EOF'
$primary: #2A76D1;
$accent:  #43D9BE;
$dark:    #141E30;
$light:   #FFFFFF;
$font-stack: 'Inter', sans-serif;
EOF

cat > _sass/_base.scss << 'EOF'
@import 'variables';
* { margin:0; padding:0; box-sizing:border-box; }
body { font-family:$font-stack; color:$dark; background:$light; line-height:1.6; }
.container { max-width:1200px; margin:0 auto; padding:0 1rem; }
.hero-bg { background-size:cover; background-position:center; }
.section-hero { position:relative; text-align:center; color:$light; padding:6rem 0; }
.btn { display:inline-block; padding:.75rem 1.5rem; border-radius:.5rem; text-decoration:none; font-weight:500; }
.btn-primary { background:linear-gradient(135deg,$accent 0%,$primary 100%); color:$light; }
.half-circle { position:absolute; bottom:0; left:50%; transform:translateX(-50%); width:120%; height:16rem; background:linear-gradient(to top,$accent,transparent); border-radius:50%; }
.feature-card { background:rgba(255,255,255,0.1); padding:1.5rem; border-radius:.5rem; }
EOF

cat > assets/css/main.scss << 'EOF'
@import "../../_sass/base";
EOF

# 8. Page stubs
echo "📄 Generating pages…"
for p in about docs extensions; do
  cat > pages/${p}.md << EOF
---
layout: default
title: "${p^}"
---

# ${p^}

(Describe the ${p} page here.)
EOF
done

cat > pages/studio.md << 'EOF'
---
layout: studio
title: "Graph Studio"
permalink: /pages/studio.html
---

# Graph Studio

(Embed and document the Graph Studio application here.)
EOF

cat > index.md << 'EOF'
---
layout: home
title: "Home"
---
EOF

# 9. Final commit
cd ..
if [ -n "$(git status --porcelain)" ]; then
  git add .
  git commit -m "chore: bootstrap clean Jekyll scaffold on main"
  echo "🎉 Scaffold committed!"
else
  echo "ℹ️ No changes to commit."
fi

echo "🚀 Done! Preview with:\n  cd site && bundle exec jekyll serve --livereload"
```  
