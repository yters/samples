# samples
This repo contains a set of demo programs in R, Python and C.



## regularization.r
The `regularization.r` R script compares ridge and lasso regularization for function regression.  

Run the script:

`RScript regularization.r`

It will produce two EPS images showing which parameter values for the regularization methods produce more accurate models than unregularized regression.

To see regularization in action, run the script from inside R interactive mode with `source("regularization.r")`.  You will see how well the different techniques are able to fit a polynomial model to a set of noisy data points sampled from a trigonometric function.

## memetic.py
The `memetic.py` Python script is a swarm simulation modelling how ideas spread virally through a population.  Additionally, the simulation shows a few individuals can significantly impact which ideas the population adopts.

Run the script:

`python memetic.py r`

Each step of the model simulation will output a line which contains the overall interest level of the population and a list of idea ID numbers and how many agents have adopted that particular idea.

The population quickly converges to a small set of ideas. This demonstrates that a few individuals can significantly impact a larger population.  

For example, the following printout shows a population converging on three ideas, signified by the numbers 515, 672 and 888. Meanwhile, the overall interest level of the population climbs from 11581 to 14592.  This printout shows population excitation and idea convergence are related.

    11581 [(354, 36), (515, 1), (528, 2), (672, 20), (888, 1)]
    12067 [(354, 48), (515, 1), (528, 1), (672, 9), (888, 1)]
    12275 [(354, 51), (515, 1), (672, 7), (888, 1)]
    12556 [(354, 45), (515, 1), (672, 13), (888, 1)]
    12874 [(354, 36), (515, 1), (672, 22), (888, 1)]
    13195 [(354, 28), (515, 1), (672, 30), (888, 1)]
    13588 [(354, 19), (515, 1), (672, 39), (888, 1)]
    14429 [(354, 4), (515, 1), (672, 54), (888, 1)]
    14592 [(515, 1), (672, 58), (888, 1)]
    14592 [(515, 1), (672, 58), (888, 1)]

For further script options type `python memetic.py -h`.

## token_counter.c

The `token_counter.c` program counts the number of occurrences of each unique token in a list of newline separated tokens.  It is equivalent to the bash oneliner `sort filename | uniq -c`, but is faster on large files.

Compile the source and make it executable:

`cc token_counter.c -o token_counter`

`chmod +x token_counter`

Run the executable on the `pigs.tokens` file, which contains all the words from *The Three Little Pigs*.

`./token_counter pigs.tokens`

You'll see a list of each token with a count of how many times it occurs, which will look like the following:

    ...
    that 6
    nursery 1
    fire 4
    dark 1
    careful 1
    texts 1
    coaxing 1
    the 74
    now 3
    ...
