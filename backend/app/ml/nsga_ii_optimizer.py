import numpy as np
from pymoo.algorithms.moo.nsga2 import NSGA2
from pymoo.core.problem import Problem
from pymoo.optimize import minimize
from pymoo.termination import get_termination

class RouteOptimizationProblem(Problem):
    def __init__(self, n_places, distance_matrix, cost_matrix, time_matrix):
        # We want to optimize 3 objectives: minimize distance, minimize cost, minimize time
        super().__init__(n_var=n_places,
                         n_obj=3,
                         n_ieq_constr=0,
                         xl=0,
                         xu=n_places-1,
                         vtype=int)

        self.distance_matrix = distance_matrix
        self.cost_matrix = cost_matrix
        self.time_matrix = time_matrix

    def _evaluate(self, X, out, *args, **kwargs):
        # X represents permutations of places (routes)
        # This is a placeholder for evaluating the fitness of routes.
        # A real implementation would calculate total distance, cost, and time for the specific route X.

        f1 = np.sum(X, axis=1) # Mock distance objective
        f2 = np.sum(X, axis=1) * 2 # Mock cost objective
        f3 = np.sum(X, axis=1) * 0.5 # Mock time objective

        out["F"] = np.column_stack([f1, f2, f3])

def run_nsga2(places_data):
    """
    Function to run the NSGA-II algorithm based on user input.
    """
    # Mock Matrices for the algorithm
    n_places = len(places_data)
    distance_matrix = np.random.rand(n_places, n_places)
    cost_matrix = np.random.rand(n_places, n_places)
    time_matrix = np.random.rand(n_places, n_places)

    problem = RouteOptimizationProblem(n_places, distance_matrix, cost_matrix, time_matrix)

    algorithm = NSGA2(pop_size=50)

    termination = get_termination("n_gen", 100)

    res = minimize(problem,
                   algorithm,
                   termination,
                   seed=1,
                   save_history=True,
                   verbose=False)

    # In a real scenario, you'd extract the Pareto front (best trade-off routes) from 'res'
    print("NSGA-II Optimization completed.")
    return {"status": "success", "message": "Optimization completed. Best routes found."}
