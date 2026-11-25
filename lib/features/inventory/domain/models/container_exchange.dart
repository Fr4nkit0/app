/// Containers handed over in one go, by container code: [returns] the
/// customer gives back, [deliveries] the driver lends (only the skeleton,
/// outside a sale).
typedef ContainerExchange = ({
  Map<String, int> returns,
  Map<String, int> deliveries,
});
