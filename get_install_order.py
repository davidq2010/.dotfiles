"""
Does stuff
"""
import json
import sys
from typing import Dict, List, Set

def compute_dep_install_order(
        deps_graph: Dict[str, List[str]])\
    -> List[str]:
    """
    Does stuff
    """
    # try to run dfs_helper, which can throw exception if DAG is found
    install_order = []
    visited = set()
    for binary in deps_graph.keys():
        if not binary in visited:
            current_traversal = []
            dfs_helper(deps_graph, binary, visited, current_traversal, install_order)
    return install_order

def dfs_helper(
        deps_graph: Dict[str, List[str]],
        curr_bin: str,
        visited: Set[str],
        current_traversal: List[str],
        install_order: List[str]):
    """
    Does stuff
    """
    if curr_bin in visited:
        return
    if curr_bin in current_traversal:
        raise ValueError(f"DAG detected in dependency graph traversal when trying to add {bin}: "
                         f"{','.join(current_traversal)}")
    # add to the front for correct dependency order
    current_traversal.append(curr_bin)
    for dependency in deps_graph[curr_bin]:
        dfs_helper(deps_graph, dependency, visited, current_traversal, install_order)
    install_order.append(curr_bin)
    visited.add(curr_bin)

# ============================================================================================
# Read deps json passed as arg and compute dependency order
if __name__ == '__main__':
    if len(sys.argv) != 2:
        raise SystemExit(f"Usage: {sys.argv[0]} <DEPENDENCIES.json>")
    deps_file = sys.argv[1]
    with open(deps_file, mode='r', encoding='utf-8') as f:
        deps_dict = json.load(f)
    deps_order = compute_dep_install_order(deps_dict)
    print(' '.join(deps_order))
# ============================================================================================

import pytest
class TestDependencyComputer:
    """
    Unit tests
    """

    def test_dfs_helper_withcycle_raiseserror(self):
        """
        dfs_helper() should raise error when graph has a cycle
        """
        graph_with_cycle = {
            'a': ['b'],
            'b': ['c'],
            'c': ['a']
        }
        with pytest.raises(ValueError):
            dfs_helper(graph_with_cycle, 'a', set(), [], [])

    def test_dfs_helper_computesinstallorderinsubgraph(self):
        """
        dfs_helper() should compute install order in subgraph
        """
        graph = {
            'a': ['b', 'c'],
            'b': ['c', 'd'],
            'c': ['d'],
            'd': []
        }
        expected_order = ['d', 'c', 'b', 'a']
        actual_order = []
        dfs_helper(graph, 'a', set(), [], actual_order)
        assert expected_order == actual_order

    def test_dfs_helper_unordered_dict_computesinstallorderinsubgraph(self):
        """
        dfs_helper() should compute install order in subgraph
        """
        graph = {
            'd': [],
            'b': ['c', 'd'],
            'c': ['d'],
            'a': ['b', 'c']
        }
        expected_order = ['d', 'c', 'b', 'a']
        actual_order = []
        dfs_helper(graph, 'a', set(), [], actual_order)
        assert expected_order == actual_order

    def test_compute_dep_install_order_computesinstallorderofentiregraph(self):
        """
        compute_dep_isntall_order() should compute install order of whole dependency graph
        """
        graph = {
            'a': ['b', 'c'],
            'b': ['c', 'd'],
            'c': ['d'],
            'd': [],
            'e': ['b', 'd']
        }
        expected_order = ['d', 'c', 'b', 'a', 'e']
        actual_order = compute_dep_install_order(graph)
        assert expected_order == actual_order
