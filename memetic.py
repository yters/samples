from sys import argv
from time import sleep
from random import seed
from random import random
from random import randint
from random import shuffle
from collections import Counter

class Torus:
    directions = [(0,1),(1,0),(0,-1),(-1,0),
                  (1,1),(1,-1),(-1,1),(-1,-1),
                  (0,2),(2,0),(0,-2),(-2,0)]

    torus_seed = None

    def __init__(self, width, height, torus_seed=None):
        self.grid = {}
        self.width = width
        self.height = height
        self.torus_seed = torus_seed
        if not self.torus_seed:
            self.torus_seed = random()
        seed(self.torus_seed)

    def place(self, agent):
        while True:
            x = randint(0, self.width-1)
            y = randint(0, self.height-1)
            if not (x,y) in self.grid:
                agent.x = x
                agent.y = y
                self.grid[(x,y)] = agent
                return
            
    def true_pos(self, x, y):
        return (x % self.width, y % self.height)

    def coord2d(self, x, y, d):
        return self.true_pos(x + d[0], y + d[1])

    def move(self, a):
        old_coord = (a.x, a.y)
        moves = self.directions + [(0,0)]
        shuffle(moves)
        for m in moves:
            new_coord = self.coord2d(a.x, a.y, m)
            if not self.grid.get(new_coord, None):
                self.grid[old_coord] = None
                a.x, a.y = new_coord
                self.grid[new_coord] = a
                return
        
    def at_pos(self, x, y):
        coord = self.true_pos(x, y)
        return self.grid.get(coord, None)
    
    def neighbors(self, a):
        ns = []
        for d in self.directions:
            n = self.at_pos(a.x + d[0], a.y + d[1])
            if n: ns += [n]
        return ns

    def __repr__(self):
        return "Torus("+str(self.width)+","+str(self.height)+","+str(self.torus_seed)+")"

    def __str__(self):
        vis = ""
        for x in range(self.width):
            vis += "\n"
            for y in range(self.height):
                if self.grid.get((x,y),None):
                    vis += str(self.grid[(x,y)].i)[0]
                else:
                    vis += " "
                vis += " "
        return vis

class Agent:
    ideas = 1000
    max_interest = 100
    decay = 1
    boost = 10
    boredom = 1
    ideas_adopted = 0

    resistor = False
    min_interest = 10

    def __init__(self):
        self.imagine()
    
    def imagine(self):
        self.i = randint(0, self.ideas)
        self.v = randint(1, self.max_interest)
        
    def interact(self, other):
        if self.resistor: return
        if other.i == self.i:
            other.v -= other.decay
            self.v -= self.decay
        elif other.v > self.v:
            Agent.ideas_adopted += 1
            self.i = other.i
            self.v = other.v
            other.v += other.boost

    def bored(self):
        if random() < 0.1: self.v -= self.decay
        if self.v < self.boredom and not self.resistor:
            self.imagine()
        elif self.resistor:
            self.v = max(self.min_interest, self.v)
            
if __name__ == "__main__":
    # Command line help.
    if "-h" in argv or "h" in argv or "--help" in argv or "help" in argv:
        print "Memetic Simulation"
        print "------------------"
        print "This is an agent swarm simulation which models the spread of ideas through a population.  The model is based on Dawkins' theory of memes.  It demonstrates that a population that operates according to memetic theory can be significantly influenced by a small number of individuals that do not obey memetic theory."
        print 
        print "60 agents live on a 2D toroid and wander around with discrete Brownian motion.  The standard agents, called memetic agents, consist of two parameters: an interest level and an idea.  When two agents are close to each other, the agent with a lower interest level will adopt the interest level and idea of the agent with the higher interest level.  The agent with the higher interest level will also gain a small boost in interest level.  If both agents have the same idea, then their interest levels decrease slightly.  If an agent is not close enough to interact with another agent during a simulation turn, its interest level will also decrease.  If an agent's interest level becomes low enough, it will randomly select a new idea and interest level.  These rules cause the population as a whole to constantly fluctuate between converging on one or a few ideas, and then discarding these ideas for a new set of ideas, which resembles how viral fads emerge, spread, and then disappear in the human population."
        print
        print "The simulation population can also have resistor agents.  These agents have the same characteristics as the memetic agents with one exception.  The resistor agents never change their idea.  The simulation shows that when two resistor agents are added to the population all the memetic agents will adopt only the ideas of the resistor agents, and fads cease to emerge.  The population will oscillate between the two ideas held by the resistor agents.  This shows it only takes a handful of individuals to exhert a significant influence on a large memetic population."
        print
        print "When the simulation is run, a summary of the population will be printed, showing total interest level of population and a list of ideas in the population with a count of adherents."
        print "E.g. 13399 [(272, 3), (529, 57)] means the total interest level is 13399 and there are two ideas in the population represented by ID numbers 272 and 529.  Idea 272 has 3 adherents and idea 529 has 57 adherents."
        print
        print "Without any options, the population only consists of memetic agents.  Use the 'r' option to add resistor agents.  Try comparing the simulation with and without resistor agents."
        print
        print "Usage: python memetic.py [vrs]"
        print
        print "Options:"
        print "  [r]esistors - Add two resistor agents to the population that do not change their idea.  These agents will cause the population to converge to the ideas they hold."
        print "  [v]isualize - Add an ASCII print out of the population.  Each agent is represented by the first digit of the idea it has."
        print "  [s]low - Slow down the simulation so it is easier to see how the population changes."
        exit()
    
    # Number of Resistor agents in the simulation.
    resistors_in_model = 0
    if "r" in argv:
        resistors_in_model = 2

    # Set up the simulation.
    torus = Torus(10,10)
    agents = []
    for i in range(0,60):
        agent = Agent()
        torus.place(agent)
        agents += [agent]

    for i in range(resistors_in_model):
        agents[i].resistor = True

    # Run the simulation for 10000 iterations, or until the user breaks with Ctrl-C.
    max_v = 0
    for i in range(10000):
        for agent in agents: torus.move(agent)
        for agent in agents:
            ns = torus.neighbors(agent)
            if len(ns) > 0: agent.interact(ns[0])
            agent.bored()

        total_v = 0
        for agent in agents: total_v += agent.v
        if total_v > max_v: max_v = total_v

        # Visualize the agent population.
        if "v" in argv: print(torus)
        
        # Represent best total interest level achieved.
        print(str(max_v) + " " + str(sorted(Counter([a.i for a in agents]).items())))

        # Slower speed so visualization can be understood.
        if "s" in argv:
            sleep(0.05)
            if "v" in argv:
                sleep(0.25)
