#pragma once

#include "Node.hpp"

namespace bt
{
class BehaviorTree : public Node
{
public:
   BehaviorTree()
   {
      root = NULL;
   }

   BehaviorTree(Node *rootNode)
   {
      root = rootNode;
   }

   Status Update()
   {
      return(root->Tick());
   }

   void SetRoot(Node *node)
   {
      root = node;
   }

   void serialize(memstream_t *stream)
   {
      root->serialize(stream);
   }

   void unserialize(memstream_t *stream)
   {
      root->unserialize(stream);
   }

private:
   Node *root;
};
}
