import 'package:copularr/core.dart';

class NZBGetQueueEntry {
    int id;
    String name;
    String status;
    String category;
    int remaining;
    int downloaded;
    int sizeTotal;
    int speed;
    int queueSeconds;

    NZBGetQueueEntry(
        this.id,
        this.name,
        this.status,
        this.remaining,
        this.downloaded,
        this.sizeTotal,
        this.category,
        this.speed,
        this.queueSeconds,
    );

    int get percentageDone {
        return sizeTotal == 0 ? 0 : ((downloaded/sizeTotal)*100).round();
    }

    bool get paused {
        return status == 'PAUSED';
    }

    double get speedMB {
        return speed/(1024*1024);
    }

    int get remainingTime {
        return speedMB == 0 ? 0 : (remaining/speedMB).floor();
    }

    String get timestamp {
        return Functions.secondsToTimestamp(queueSeconds+remainingTime) == '0:00:00' ? '―' : Functions.secondsToTimestamp(queueSeconds+remainingTime);
    }

    String get statusString {
        switch(status) {
            case 'DOWNLOADING':
            case 'QUEUED': {
                return speed == -1 ? 'Downloading' : timestamp;
            }
            case 'PAUSED': {
                return 'Paused';
            }
            default: {
                return status;
            }
        }
    }

    String get subtitle {
        String size = '$downloaded/$sizeTotal MB';
        return '$statusString\t•\t$size\t•\t$percentageDone%';
    }
}
