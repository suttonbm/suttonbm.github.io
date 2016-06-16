---
layout: page
title: "Arduino GPS"
excerpt: "Logging Hikes the DIY Way"
search_omit: true
categories:
  - projecthome
---

<ul class="post-list">
{% for post in site.posts %}
{% if post.project == 'arduinogps' %}
  <li><article><a href="{{ site.url }}{{ post.url }}">{{ post.title }} <span class="entry-date"><time datetime="{{ post.date | date_to_xmlschema }}">{{ post.date | date: "%B %d, %Y" }}</time></span>{% if post.excerpt %} <span class="excerpt">{{ post.excerpt | remove: '\[ ... \]' | remove: '\( ... \)' | markdownify | strip_html | strip_newlines | escape_once }}</span>{% endif %}</a></article></li>
{% endif %}
{% endfor %}
</ul>