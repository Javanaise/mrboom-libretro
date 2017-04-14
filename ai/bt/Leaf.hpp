#pragma once

#include "Node.hpp"
#include <vector>
#include <memory>

namespace bt
{

class Leaf : public Node
{
public:
    Leaf() {}
    virtual ~Leaf() {}
    
    virtual Status Update() = 0;
};

}
