#pragma once

#include "Node.hpp"

namespace bt
{

class BehaviorTree : public Node
{
public:
BehaviorTree() {
}
BehaviorTree(const Node::Ptr &rootNode) : BehaviorTree() {
	root = rootNode;
}

Status Update() {
	return root->Tick();
}

void SetRoot(const Node::Ptr &node) {
	root = node;
}

private:
Node::Ptr root = nullptr;
};

}
