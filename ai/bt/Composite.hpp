#pragma once

#include "Node.hpp"

namespace bt
{

class Composite : public Node
{
public:

  Composite() {
    index = 0;
  }
    virtual ~Composite() {}

    void AddChild(Node * child) { children.push_back(child); }
    bool HasNoChildren() const { return children.empty(); }
    int GetIndex() const { return index; }

protected:
    std::vector<Node *> children;
    int index;
};

}
