#pragma once

#include "Node.hpp"

namespace bt
{

class BehaviorTree : public Node
{
public:
BehaviorTree() {
	root = nullptr;
}
BehaviorTree(Node * rootNode) {
	root = rootNode;
}

Status Update() {
	return root->Tick();
}

void SetRoot(Node * node) {
	root = node;
}

private:
Node * root;
};

}
