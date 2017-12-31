from random import random
from random import randint
from random import shuffle
from collections import Counter

class Torus:
    directions = [(0,1),(1,0),(0,-1),(-1,0),
                  (1,1),(1,-1),(-1,1),(-1,-1),
                  (0,2),(2,0),(0,-2),(-2,0)]

    def __init__(self, width, height):
        self.grid = {}
        self.width = width
        self.height = height

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
    # Number of Resistor agents in the simulation.
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

    # Run the simulation until the user breaks with Ctrl-C.
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

        # Represent best total interest level achieved.
        print(str(max_v) + " " + str(sorted(Counter([a.i for a in agents]).items())))
