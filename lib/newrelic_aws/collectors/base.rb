module NewRelicAWS
  module Collectors
    class Base
      def initialize(access_key, secret_key, region)
        @aws_access_key = access_key
        @aws_secret_key = secret_key
        @aws_region = region
        @cloudwatch = AWS::CloudWatch.new(
          :access_key_id     => @aws_access_key,
          :secret_access_key => @aws_secret_key,
          :region            => @aws_region
        )
        @last_data_points = {}
      end

      def get_data_point(options)
        options[:period]     ||= 60
        options[:start_time] ||= (Time.now.utc-120).iso8601
        options[:end_time]   ||= (Time.now.utc-60).iso8601
        statistics = @cloudwatch.client.get_metric_statistics(
          :namespace   => options[:namespace],
          :metric_name => options[:metric_name],
          :unit        => options[:unit],
          :statistics  => ["Sum"],
          :period      => options[:period],
          :start_time  => options[:start_time],
          :end_time    => options[:end_time],
          :dimensions  => [options[:dimension]]
        )
        point = statistics[:datapoints].last
        data_point_id = [options[:dimension][:value], options[:metric_name]].join("/")
        return if point.nil? || point[:timestamp] == @last_data_points[data_point_key]
        @last_data_points[data_point_id] = point[:timestamp]
        [options[:dimension][:value], options[:metric_name], point[:unit].downcase, point[:sum]]
      end

      def collect
        []
      end
    end
  end
end
