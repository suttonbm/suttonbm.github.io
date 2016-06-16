---
layout: page
title: Projects
excerpt: "Fun projects."
search_omit: true
---

<ul class="post-list">
{% for page in site.pages %} 
{% if page.categories contains 'projecthome' %}
  <li>
  <article>
  <a href="{{ site.url }}{{ page.url }}">
    {{ page.title }}
  {% if page.excerpt %}
    <span class="excerpt">{{ page.excerpt | remove: '\[ ... \]' | remove: '\( ... \)' | markdownify | strip_html | strip_newlines | escape_once }}</span>
  {% endif %}
  </a>
  </article>
  </li>
{% endif %}
{% endfor %}
</ul>
