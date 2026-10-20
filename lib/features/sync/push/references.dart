import 'entity_pusher.dart';

/// A reference between pushed records: the server id once the referenced
/// record has one, its client uuid otherwise (the server resolves it within
/// the same request, which it processes in dependency order).
Json reference(String name, {required int? serverId, required String uuid}) =>
    serverId != null ? {'${name}_id': serverId} : {'${name}_uuid': uuid};
