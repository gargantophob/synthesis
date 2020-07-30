#pragma once

#include <vector>
#include <boost/optional.hpp>

namespace storm {
    
    namespace expressions {
        class Variable;
    }
    
    namespace jani {
        
        class Model;
        class Property;
        
        class JaniScopeChanger {
        public:
            JaniScopeChanger() = default;
            
            /*!
             * Moves the given variable to the global scope.
             * It is *not* checked whether this introduces name clashes
             */
            void makeVariableGlobal(storm::expressions::Variable const& variable, Model& model) const;
            
            /*!
             * Moves the given variable into the local scope of the automaton with the given index.
             * It is *not* checked whether this introduces out-of-scope accesses.
             */
            void makeVariableLocal(storm::expressions::Variable const& variable, Model& model, uint64_t automatonIndex) const;
            
            /*!
             * Checks whether this variable can be made global without introducing name clashes.
             */
             bool canMakeVariableGlobal(storm::expressions::Variable const& variable, Model const& model) const;
             
            /*!
             * Checks whether this variable can be made local without introducing out-of-scope accesses.
             * Returns true if this is a case as well as an automaton index where to pout the variable
             */
             std::pair<bool, uint64_t> canMakeVariableLocal(storm::expressions::Variable const& variable, Model const& model, std::vector<Property> const& properties = {}, boost::optional<uint64_t> automatonIndex = boost::none) const;
             
            /*!
             * Moves as many variables to the global scope as possible
             */
             void makeVariablesGlobal(Model& model) const;
             
            /*!
             * Moves as many variables to a local scope as possible
             */
             void makeVariablesLocal(Model& model, std::vector<Property> const& properties = {}) const;
             
        };
    }

}
