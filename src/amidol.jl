json_schema = """
{ "irModel": {
  "irModelName": "string",
  "stateVariables": [{
    "name": "string",
    "label": "string",
    "type": "sv_type",
    "initial_value": "expression"
  }],
  "events": [{
    "name": "string",
    "label": "string",
    "rate": "expression",
    "input_predicate": {
      "enabling_condition": "expression"
    },
    "output_predicate": {
      "transition_function": ["lvalue = expression", "lvalue = expression", ...]
    }
  }],
  "constants": [{
    "name": "string",
    "value": "extern"|"expression"
  }],
  "expressions": [{
    "name": "string",
    "value": "extern"|"expression"
  }],
  "rateRewards": [{
    "name": "string",
    "variable": "string",
    "temporaltype": "instantoftime"|"intervaloftime"|"timeaveragedintervaloftime"|"steadystate",
    "samplingpoints": [{
      "time": "float"
      }]    
  }],
  "impulseRewards": [{
    "name": "string",
    "event": "string",
    "temporaltype": "instantoftime"|"intervaloftime"|"timeaveragedintervaloftime"|"steadystate",
    "samplingpoints": [{
      "time": "float"
      }]    
  }],
  "composedrewards": [{
    "name": "string",
    "expression": "expression"
  }]
 }}
"""

struct IRModel{T}
    name::String
    stateVariables::T
    events::E
    constants::C
    expressions::X
    rewards::R
end

struct Event{P,Q}
    name::String
    label::String
    rate::Expression
    input_predicate::P
    output_predicate::q
end

struct Input
    enabling_condition::Expression
end

struct Output
    transition::Expr
end

struct Constant{T}
    name::String
    value::T
end

struct Expression{T}
    name::String
    value::T
end

struct Rewards
    rate
    impulse
    composed
end

struct ComposedReward
    name
    expression
end

struct ImpulseReward
    name::String
    event::String
    temporaltype
    samplingpoints::Vector{Time}
end

struct RateRewards
    name
    variable
    temporaltype
    samplingpoints
end

