from present_list import KnessetPresenceParser
from datetime import datetime
import time, os


SLEEP_TIME_BETWEEN_CHECKS = int(os.environ.get('SLEEP_TIME_BETWEEN_CHECKS', 7 * 60))  # 7 minutes
RESULTS_FILE = os.environ.get('RESULTS_FILE', 'presence.txt')


class PresenceManager(object):
    '''
    This class responsible for running and updating the MKs precence according to the knesset presence website
    '''

    __last_presence_check = None
    __log_file = None

    def run(self):
        self._write_log('--- %s --- Starting running kneset presence check ' % str(datetime.now()))
        self._write_log('--- SLEEP_TIME_BETWEEN_CHECKS = {} ---'.format(SLEEP_TIME_BETWEEN_CHECKS))
        self._write_log('--- RESULTS_FILE = {} ---'.format(RESULTS_FILE))
        os.makedirs(os.path.dirname(RESULTS_FILE))
        while True:
            # self._write_log('--- %s --- Parsing kneset HTML' % str(datetime.now()) )
            try:
                presence_parser = KnessetPresenceParser()
            except Exception as e:
                self._write_log(
                    '--- %s --- Can\'t create KnessetPresenceParser: %s  - Going to sleep' % (str(datetime.now()), e))
                time.sleep(SLEEP_TIME_BETWEEN_CHECKS)
                continue

            if presence_parser.lastupdate_date == self.__last_presence_check:
                self._write_log('--- %s --- No new updates. Going to sleep' % str(datetime.now()))
                time.sleep(SLEEP_TIME_BETWEEN_CHECKS)
                continue

            self.__last_presence_check = presence_parser.lastupdate_date
            self._write_log(
                '--- %s --- The HTML have been updated in %s' % (str(datetime.now()), str(presence_parser.lastupdate_date)))
            mk_presence = presence_parser.get_present_mks_ids()
            self._write_results(str(presence_parser.lastupdate_date) + ", " + ", ".join([str(mk) for mk in mk_presence]))
            # for mk in l:
            #    self._write_log("MK id=%d present in %s" % (mk, str(k.lastupdate_date)) )
            time.sleep(SLEEP_TIME_BETWEEN_CHECKS)

    def _write_log(self, msg):
        print(msg)

    def _write_results(self, msg):
        self.__log_file = file(RESULTS_FILE, 'a')
        self.__log_file.write(msg + "\n")
        self.__log_file.close()


if __name__ == '__main__':
    pm = PresenceManager()
    pm.run()
