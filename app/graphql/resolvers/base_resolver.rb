module Resolvers
  class BaseResolver < GraphQL::Schema::Resolver
    include AuthorizationHelper
  end
end
