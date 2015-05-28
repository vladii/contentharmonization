// Given two binary matrices (one in matrix.in file and the other one in matrix.ref)
// compute the distance between their 1 values. Build a graph and run Max Flow Min Cost.
#include <iostream>
#include <fstream>
#include <algorithm>
#include <cstdio>
#include <cstring>
#include <vector>
#include <queue>
using namespace std;
#define maxn 256 + 10
#define maxnodes 2048
#define inf 100000
#define inf2 9999999
#define COST_UNMATCHED 50
#define x first
#define y second

int Nm, Mm, Nr, Mr;
int N1, N2;     // Number of nodes of both images
int matrix_mine[maxn][maxn];
int matrix_ref[maxn][maxn];
vector<pair<int, int> > nodes_mine;
vector<pair<int, int> > nodes_ref;

int S, D;                   // Max-flow source and destination
vector<pair<int, int> > G[maxnodes * 2];  // Graph with edges and costs
int cap[maxnodes * 2][maxnodes * 2];      // Capacity matrix
int flow[maxnodes * 2][maxnodes * 2];     // Flow matrix
int dist[maxnodes * 2], father[maxnodes * 2], inQueue[maxnodes * 2];

int computeCost(const pair<int, int>& firstNode, const pair<int, int>& secondNode) {
    // Compute euclidian distance
    int dst = (firstNode.x - secondNode.x) * (firstNode.x - secondNode.x) +
              (firstNode.y - secondNode.y) * (firstNode.y - secondNode.y);
    
    return dst;
}

int BellmanFord() {
    // Bellman Ford algorithm for finding minimum paths
    queue<int> Q;
    memset(dist, 0, sizeof(dist));
    memset(father, 0, sizeof(father));
    memset(inQueue, 0, sizeof(inQueue));
    
    for (int i = S; i <= D; i++) {
        dist[i] = inf2;
    }
    
    Q.push(S);
    inQueue[S] = 1;
    father[S] = -1;
    dist[S] = 0;

    while (!Q.empty()) {
        int node = Q.front(); Q.pop();
        inQueue[node] = 0;
        
        for (int i = 0; i < G[node].size(); i++) {
            int vec = G[node][i].first;
            int cost = G[node][i].second;
            
            if (flow[node][vec] < cap[node][vec] && dist[node] + cost < dist[vec]) {
                dist[vec] = dist[node] + cost;
                father[vec] = node;
                
                if (!inQueue[vec]) {
                    Q.push(vec);
                    inQueue[vec] = 1;
                }
            }
        }
    }
    
    if (dist[D] < inf2) {
        int flowPath = inf2;
        
        for (int i = D; i != S; i = father[i]) {
            flowPath = min(flowPath, cap[father[i]][i] - flow[father[i]][i]);
        }
        
        for (int i = D; i != S; i = father[i]) {
            flow[father[i]][i] += flowPath;
            flow[i][father[i]] -= flowPath;
        }
        
        return flowPath * dist[D];
    }
    
    return -1;   // No more paths
}

int main(int argc, char** argv) {
    if (argc < 3) {
        cout << "Usage: ./test matrix_input_file matrix_ref_file" << endl;
        return 0;
    }
    
    fstream f1, f2;
    f1.open(argv[1], ios::in);
    f2.open(argv[2], ios::in);
    
    // Read both matrices
    f1 >> Nm >> Mm;
    for (int i = 1; i <= Nm; i++) {
        for (int j = 1; j <= Mm; j++) {
            f1 >> matrix_mine[i][j];
            
            if (matrix_mine[i][j] == 1) {
                N1 ++;
                nodes_mine.push_back(make_pair(i, j));
            }
        }
    }
    
    f2 >> Nr >> Mr;
    for (int i = 1; i <= Nr; i++) {
        for (int j = 1; j <= Mr; j++) {
            f2 >> matrix_ref[i][j];
            
            if (matrix_ref[i][j] == 1) {
                N2 ++;
                nodes_ref.push_back(make_pair(i, j));
            }
        }
    }
    
    f1.close();
    f2.close();
    
    cout << N1 << " points of interest in input matrix!" << endl;
    cout << N2 << " points of interest in ref matrix" << endl;
    
    // Construct a bipartite graph
    // N2 nodes in the left part [1 ... N2]
    // N1 + N2 nodes in the right part [N2+1 ... N2+N1]
    for (int i = 1; i <= N2; i++) {
        pair<int, int> curr_node = nodes_ref[i - 1];
        
        for (int j = 1; j <= N1; j++) {
            pair<int, int> vec_node = nodes_mine[j - 1];
            
            // Edge between curr_node and vec_node
            G[i].push_back(make_pair(N2 + j, computeCost(curr_node, vec_node)));
            G[N2 + j].push_back(make_pair(i, computeCost(vec_node, curr_node)));
            
            cap[i][N2 + j] = 1;
        }
    }
    
    // Define source and destination
    // Edge between source and all left nodes
    S = 0;
    for (int i = 1; i <= N2; i++) {
        G[S].push_back(make_pair(i, 0));
        G[i].push_back(make_pair(S, 0));
        
        cap[S][i] = 1;
    }
    
    // Edge between all right nodes and destination
    D = N1 + N2 + 1;
    for (int i = N2 + 1; i <= N1 + N2; i++) {
        G[i].push_back(make_pair(D, 0));
        G[D].push_back(make_pair(i, 0));
        
        cap[i][D] = 1;
    }
    
    // Run Max-flow with source S and destination D, on graph G
    int minCost = 0;
    int costAdded = 1;
    
    while (costAdded >= 0) {
        costAdded = BellmanFord();
        
        if (costAdded >= 0)
            minCost += costAdded;
    }
    
    // Compute number of unmatched nodes from the left part.
    int unmatchedNodes = 0;
    
    for (int i = 0; i < G[S].size(); i++) {
        int vec = G[S][i].first;
        
        if (flow[S][vec] == 0 && cap[S][vec] > 0) {
            // Unmatched node.
            unmatchedNodes ++;
        }
    }
    
    
    // Print the solution
    cout << "Number of matched points: " << N2 - unmatchedNodes << endl;
    cout << "Number of unmatched points: " << unmatchedNodes << endl;
    cout << "Cost: " << minCost + unmatchedNodes * COST_UNMATCHED << '\n';
    
    return 0;
}
