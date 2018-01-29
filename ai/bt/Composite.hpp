#pragma once

#include "Node.hpp"

namespace bt
{
class Composite : public Node
{
public:

   Composite()
   {
      index = 0;
   }

   virtual ~Composite()
   {
   }

   void AddChild(Node *child)
   {
      children.push_back(child);
   }

   bool HasNoChildren() const
   {
      return(children.empty());
   }

   int GetIndex() const
   {
      return(index);
   }

   void serialize(memstream_t *stream)
   {
      // TOFIX big endian
      Node::serialize(stream);
      memstream_write(stream, &index, sizeof(index));
      for (int i = 0; i < (signed)children.size(); i++)
      {
         bt::Node *child = children.at(i);
         child->serialize(stream);
      }
   }

   void unserialize(memstream_t *stream)
   {
      // TOFIX big endian
      Node::unserialize(stream);
      memstream_read(stream, &index, sizeof(index));
      for (int i = 0; i < (signed)children.size(); i++)
      {
         bt::Node *child = children.at(i);
         child->unserialize(stream);
      }
   }

protected:
   std::vector <Node *> children;
   uint8_t index;
};
}
