# frozen_string_literal: true

module GF180DRC
  Deck = Struct.new(:id, :path, :tags, :runner, keyword_init: true)

  # Registers all available drc checks. Could be extended to provide filtering
  class Registry
    def initialize
      @decks_by_id = {}
      @order = []
    end

    # Register or replace a deck. Replacement is useful with `load` during development.
    def register(id:, path:, tags: [], &runner)
      raise ArgumentError, "register requires a block for deck '#{id}'" unless block_given?

      if @decks_by_id.key?(id)
        # replace in-place, preserve ordering
        @decks_by_id[id] = Deck.new(id: id, path: path, tags: tags, runner: runner)
      else
        @decks_by_id[id] = Deck.new(id: id, path: path, tags: tags, runner: runner)
        @order << id
      end
    end

    def all
      @order.map { |id| @decks_by_id.fetch(id) }
    end

    # include_tags: array; match if any tag overlaps
    def select(include_tags: nil, raise_on_empty: true)
      decks = all

      decks = decks.select { |d| (d.tags & include_tags).any? } if include_tags && !include_tags.empty?

      if raise_on_empty && decks.empty?
        raise ArgumentError,
              'Deck selection matched no decks. ' \
              "Filters: include_tags=#{include_tags.inspect} " \
              "Available tags : #{all.map(&:tag).join(', ')}"
      end

      decks
    end
  end
end
