# frozen_string_literal: true

require 'ruby_postal/parser'

class GeocodeQueriesController < ApplicationController
  def index
    q = GeocodeQuery.all.order(created_at: :desc).includes(:geocode_results)
    respond_to do |format|
      format.html do
        @geocode_queries = q.paginate(page: params[:page], per_page: 50)
      end
      format.csv do
        send_data q.to_csv, filename: "geocode-queries-#{Time.zone.today}.csv"
      end
    end
  end

  def show
    @geocode_query = GeocodeQuery.find(params[:id])
    @address_split = Postal::Parser.parse_address(@geocode_query.query)
  end
end
