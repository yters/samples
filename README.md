# samples
This repo contains a set of demo programs in R, Python and C.



## lasso.r
The `lasso.r` R script compares ridge and lasso regularization for function regression.  

Run the script:

`RScript lasso.r`

It will produce two EPS images showing which parameter values for the regularization methods produce more accurate models than unregularized regression.

## memetic.py
The `memetic.py` Python script is an agent swarm model demonstrating how ideas spread virally through a population, and how a few individuals can significantly impact which ideas the population adopts.

Run the script:

`python memetic.py`

Each step of the model simulation will output a line which contains the overall interest level of the population and a list of idea ID numbers and how many agents have adopted that particular idea.

The population quickly converges to a small set of ideas, which demonstrates how it only takes a few individuals to significantly impact a large population.

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
