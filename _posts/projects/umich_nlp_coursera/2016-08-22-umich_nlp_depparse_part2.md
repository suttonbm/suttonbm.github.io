---
layout: post
author: suttonbm
date: 2016-08-22
categories:
  - projects
title: "UMich NLP Dependency Parsing - Implementation"
tags:
  - python
  - nlp
  - umich
  - coursera
project: umich_nlp_coursera
excerpt: >
  Dependency Parsing - Implementation
--- 
### Implementation of the Operations
First, let's discuss implementation of the four supported operations of our
shift-reduce parser.  As discussed in [part 1]({{ base.url
}}/2016/08/umich_nlp_depparse_intro/), the four supported operations are
`left_arc()`, `right_arc()`, `shift()`, and `reduce()`. 
 
#### Left Arc 

**In [12]:**

{% highlight python %}
def left_arc(conf, relation):
    if not conf.buffer:
        return -1

    if conf.stack[-1] == 0:
        return -1

    for arc in conf.arcs:
        if conf.stack[-1] == arc[2]:
            return -1

    b = conf.buffer[0]
    s = conf.stack.pop(-1)
    # Add the arc (b, L, s)
    conf.arcs.append((b, relation, s))
    pass
# END left_arc
{% endhighlight %}
 
#### Right Arc 

**In [9]:**

{% highlight python %}
def right_arc(conf, relation):
    if not conf.buffer or not conf.stack:
        return -1

    s = conf.stack[-1]
    b = conf.buffer.pop(0)

    conf.stack.append(b)
    conf.arcs.append((s, relation, b))
    pass
# END right_arc
{% endhighlight %}
 
#### Reduce 

**In [13]:**

{% highlight python %}
def reduce(conf):
    if not conf.stack:
        return -1

    for arc in conf.arcs:
        if conf.stack[-1] == arc[2]:
            s = conf.stack.pop(-1)
            return
    return -1
# END reduce
{% endhighlight %}
 
#### Shift 

**In [7]:**

{% highlight python %}
def shift(conf):
    if not conf.buffer or not conf.stack:
        return -1

    b = conf.buffer.pop(0)
    conf.stack.append(b)
    pass
# END shift
{% endhighlight %}
 
As might be expected, the implementation of the functions is straightforward.
No explanation of the logic is given, but I think the reader should be able to
interpret fairly easily. 
 
### Extraction of Features
The four functions of the shift-reduce parser above define the actions that are
available for a given configuration, but we need a brain to tell the program
when to apply which function.  As discussed in part 1, we could try to create
some hard-coded rules based on various configurations.  However, with this
approach, the program would be inflexible and likely perform poorly.  Instead,
we can use supervised machine learning to have the program learn for itself how
to apply the shift-reduce functions.

As with any supervised learning problem, we need two things - a set of golden
data to train the machine, and a method of extracting useful features from that
golden data.  For this problem, we were provided golden data in the form of
CONLL datasets for english, danish, and swedish.  This dataset essentially
provides a series of configurations accompanied by the correct operation and
label (if applicable).  Our assignment was to extract "features" from each
configuration - properties about the configuration which provide positive
predictive value for the operation to be used.

I made multiple iterations to converge to a solution; these are outlined below. 
 
#### Data Structures
Before getting into the iterations on the feature extractor, let's first define
the data structure that is used the the extractor.  As discussed previously,
there are three components of a parser configuration.  $$B$$ is the buffer,
remaining words to be parsed.  $$\Sigma$$ is the stack, holding words that have
been processed via the `right_arc()` or `shift()` operations.  $$A$$ is the set of
arcs that have been added to the dependency graph.

Note that $$B$$ and $$\Sigma$$ both contain words, which may have a variety of
properties.  Therefore it may make sense to index those words and store them in
a separate data structure.  Let's call that $$T$$, a list of dictionaries storing
the properties of each word.

Let's take a look at an example. 

**In [2]:**

{% highlight python %}
import random
from providedcode import dataset
data = dataset.get_english_train_corpus().parsed_sents()
smalldata = random.sample(data, 5)
{% endhighlight %}
 
Let's generate a partially completed configuration to see what it looks like. 

**In [17]:**

{% highlight python %}
from providedcode.transitionparser import Configuration

def getDepRelation(parent, child, graph):
    p_node = graph.nodes[parent]
    c_node = graph.nodes[child]
    
    if c_node['word'] is None:
        return None
    if c_node['head'] == p_node['address']:
        return c_node['rel']
    else:
        return None
    pass

testGraph = smalldata[0]
conf = Configuration(testGraph, None)
for k in range(11):
    b0 = conf.buffer[0]
    if conf.stack:
        s0 = conf.stack[-1]
        
        # Look for left-arc relationship
        rel = getDepRelation(b0, s0, testGraph)
        if rel is not None:
            left_arc(conf, rel)
            continue
        
        # Look for right-arc relationship
        rel = getDepRelation(s0, b0, testGraph)
        if rel is not None:
            right_arc(conf, rel)
            continue
        
        # Look for reduce
        flag = False
        for k in range(s0):
            if getDepRelation(k, b0, testGraph) is not None:
                flag = True
            if getDepRelation(b0, k, testGraph) is not None:
                flag = True
        if flag:
            reduce(conf)
            continue
    
    # By default, apply shift
    shift(conf)
{% endhighlight %}
 
Interpretation of the above code is left as an exercise to the reader.
Essentially, we've taken a single sentence from the golden source and applied
the first ten operations to it in order.  We should be left with a partially
completed configuration for further inspection. 
 
First, let's inspect the stack: 

**In [18]:**

{% highlight python %}
conf.stack
{% endhighlight %}




    [0, 6]


 
The correct way to interpret the stack is to see the leftmost element as the
bottom and the rightmost element as the top.  We can see that the current
configuration of the stack has two items.  The first is word '6', and the last
is the root element, '0'. 

**In [19]:**

{% highlight python %}
conf.buffer
{% endhighlight %}




    [7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18]


 
The buffer is interpreted in the opposite way.  The leftmost element is the
"next" item in the buffer, and the rightmost element is the "last" item. 

**In [20]:**

{% highlight python %}
conf.arcs
{% endhighlight %}




    [(1, u'adpmod', 2),
     (4, u'det', 3),
     (2, u'adpobj', 4),
     (6, u'auxpass', 5),
     (6, u'csubjpass', 1),
     (0, u'ROOT', 6)]


 
At this point, six dependency relations have now been added to the dependency
map.  For example, '3' depends on '4', and the relationship is 'det', or
determiner.

Let's confirm this by looking at the words themselves. 

**In [22]:**

{% highlight python %}
print testGraph.nodes[3]['word']
print testGraph.nodes[4]['word']
{% endhighlight %}

    the
    father
    
 
So we see that the dependency relation specified above makes sense.  "the"
depends on "father" because it is the determiner for "father".  We could replace
"the" with "a" and have the same result!

Finally, there are many different properties stored for the words.  Let's take a
look. 

**In [23]:**

{% highlight python %}
testGraph.nodes[3].keys()
{% endhighlight %}




    [u'ctag',
     u'head',
     u'word',
     u'rel',
     u'lemma',
     u'tag',
     u'deps',
     u'address',
     u'feats']


 
Not all of these properties are useful for training our SVM.  The descriptions
of useful properties are as follows:

  * 'ctag': Coarse-grained part of speech.  For example, "NOUN"
  * 'tag': Fine-grained part of speech. For example, "NNS", or singular noun
  * 'word': The word itself 
 
Now that we see how the data is being stored, let's take a look at the task of
feature extraction. 
 
#### Iteration #1 - POS Tags Unigram Model
The first iteration of the feature extractor only made use of the coarse-grained
part of speech for the top word in the stack and the buffer.  For example,
$$S=['company',...]$$ and $$\Sigma=['was',...]$$ might identify two features.
"Company" would be a "NOUN" and "was" would be a "VERB".

In code, this might look like: 

**In [27]:**

{% highlight python %}
s = conf.stack[-1]
tok = testGraph.nodes[s]
"STK_0_CTAG_{0}".format(tok['ctag'].upper())
{% endhighlight %}




    'STK_0_TAG_VERB'


 
Using only this feature, the SVM was able to achieve ~47% accuracy.  Changing to
the fine-grained part of speech improved accuracy to ~53%. 
 
#### Iteration #2 - Parents / Children in Queue
The second iteration looks at whether there is an arc already created where the
target word is a parent or a child.  In addition, if a dependency relation
exists, the label for that relation is noted.  The target is limited to the top
word in the stack or the buffer.

The implementation is as follows: 

**In [31]:**

{% highlight python %}
def getNDeps(n, arcs):
    parents = 0
    children = 0

    for arc in arcs:
        if arc[0] == n:
            children += 1
        # END if
        if arc[2] == n:
            parents += 1
    # END for

    return (parents, children)
{% endhighlight %}
 
Then features are extracted as follows: 

**In [33]:**

{% highlight python %}
(parents, children) = getNDeps(s, conf.arcs)
print "STK_0_PARENTS_{0}".format(parents>0)
print "STK_0_CHILDREN_{0}".format(children>0)
{% endhighlight %}

    STK_0_PARENTS_True
    STK_0_CHILDREN_True
    
 
Adding this feature to the data improved accuracy to ~60%. 
 
#### Iteration #3 - N-Gram POS Model
In the third (and final) iteration, the part of speech extraction was upgraded
from a unigram to a trigram model.  Rather than looking only at the top word in
the stack and buffer, the part of speech was extracted from the next two items
in each as well.

Features extracted as follows: 

**In [36]:**

{% highlight python %}
if len(conf.stack) >= 2:
    next_s = conf.stack[1]
    next_Tok = testGraph.nodes[next_s]
    if next_s == 0:
        print "STK_1_ROOT"
    else:
        print "STK_1_TAG_{0}".format(next_Tok['tag'].upper())
else:
    print "STK_1_NULL"
if len(conf.stack) >= 3:
    later_s = conf.stack[2]
    next_Tok = testGraph.nodes[later_s]
    if later_s == 0:
        print "STK_2_ROOT"
    else:
        print "STK_2_TAG_{0}".format(next_Tok['tag'].upper())
else:
    print "STK_2_NULL"
{% endhighlight %}

    STK_1_TAG_VBN
    STK_2_NULL
    
 
Using this final feature extraction method, ~67% accuracy was achieved. 

**In [None]:**

{% highlight python %}

{% endhighlight %}
