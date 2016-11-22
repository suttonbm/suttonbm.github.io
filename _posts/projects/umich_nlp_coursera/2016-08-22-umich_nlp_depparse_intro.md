---
layout: post
author: suttonbm
date: 2016-08-22
categories:
  - projects
title: "UMich Dependency Parsing - Intro"
tags:
  - python
  - nlp
  - umich
  - coursera
project: umich_nlp_coursera
excerpt: >
  Introduction to the dependency parsing project
--- 
#### Syntax Dependency Parsing
Syntax dependency parsing, as might be inferred by the name, is a process by
which a string of words can be placed into a formal grammar structure.  I use
these terms loosely, as the definition of a "word" or the formalization of a
"grammar structure" can be interpreted in many different ways.  For the purpose
of this assignment, we'll use the lay definition of a "word" - i.e. words of a
language, and "grammar structure" can be taken to mean the series of
hierarchical relationships different words have to one another.

What do I mean by this?

For example, consder the sentence "I eat cake".  With a basic understanding of
english grammar, we can immediately identify "I" to be the subject, "cake" to be
a direct object, and "eat" to be a verb relating the subject and direct object.
If we were to think of this sentence programmatically, we might translate the
sentence to:
```
eat("I", "cake")
```

In order for the function, or verb, to "execute" correctly, it needs two
arguments: a subject and a direct object.

This type of thinking can be extended to higher complexity phrases, but this
will be left as an exercise to the reader. 
 
#### Supervised Learning of Dependency Parsing
One challenge in creating a way to programmatically determine the dependency
structure of written language is that a formal set of grammar rules is often not
available.  In addition, trying to use a purely rules-based approach can be
challenging or impossible if trying to parse languages the programmer is not
familiar with.

Thus, we can approach dependency parsing as a supervised learning problem.
Using "golden" dependency data, we can train a program to create "rules" which
maximize the accuracy of dependency trees on that data, then apply those rules
to new, unseen data to obtain a dependency tree. 
 
#### Structure of a Dependency Graph
The dependency graph of a sentence $$ S = w_1, w_2, ... , w_n $$ is a directed
graph $$ G = (V, A) $$, where $$V$$ is the set of words (nodes), and $$A$$ is the set
of labeled dependencies (arcs).

The arc $$i \rightarrow j$$ specifies a dependency relationship from $$j$$ to $$i$$,
and we can say that the **head** of the dependency is $$w_i$$ and its
**dependent** is $$w_j$$. 
 
#### The Shift-Reduce Parser [1]
We can define a simple shift-reduce parser as an algorithm which, operates on a
**configuration**, consisting of a *stack* and a *buffer*.  There are four basic
operations:

  * Left Arc: Add a left-pointing dependency relation
  * Right Arc: Add a right-pointing dependency relation
  * Shift: Remove a word from the *buffer* and push it onto the *stack*
  * Reduce: Remove the top word in the *stack*

Formally, the configuration $$C$$ is defined by the tuple $$(\Sigma, B, A)$$, where
$$\Sigma$$ is the stack, $$B$$ is the buffer, and $$A$$ is a set of specified
dependency relations.

If we define the next (top) node in $\Sigma$ as $$s$$ and the next node in $$B$$ as
$$b$$, and define the label (name) of a dependency relation $$L$$:

 * $$left\_arc(C)$$ : add arc $$(b, L, s)$$ and remove $$s$$ from $$\Sigma$$
 * $$right\_arc(C)$$ : add arc $$(s, L, b)$$ and push $$b$$ onto $$\Sigma$$
 * $$shift(C)$$ : push $$b$$ onto $$\Sigma$$ without an arc
 * $$reduce(C)$$ : remove $$s$$ from $$\Sigma$$

Note that not all of the transitions are valid for all possible configurations:

 * $$left\_arc()$$ is invalid if:
   * (a) $$B$$ is empty
   * (b) $$s$$ is the root node $$0$$, or
   * (c) $$\exists a \in A$$ where $$s$$ is a dependent
 * $$right\_arc()$$ is invalid if:
   * (a) $$B$$ is empty, or
   * (b) $$\Sigma$$ is empty
 * $$shift()$$ is invalid if:
   * (a) $$\Sigma$$ is empty, or
   * (b) $$\neg \exists a \in A$$ where $$s$$ is a dependent
 * $$reduce()$$ is invalid if:
   * (a) $$B$$ is empty, or
   * (b) $$\Sigma$$ is empty 
 
#### Implementation of the Shift-Reduce Parser
The shift-reduce parser can be trained to determine correct operations on a
given configuration $C$ using a support vector machine. The implementation of
this machine is discussed further in [part 2]({{ base.url
}}/2016/08/umich_nlp_depparse_part2/)
