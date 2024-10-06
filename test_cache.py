import random
import time
import unittest

import requests


class TestPrefetchCaching(unittest.TestCase):
    ORIGIN_SHIELD_URL = "http://localhost:8080"
    SEGMENTS = [f"{i}.ts" for i in range(10)]

    def test_prefetch_behavior(self):
        current_segment = random.choice(self.SEGMENTS[:-1])
        next_segment = f"{int(current_segment.split('.')[0]) + 1}.ts"

        response_current = requests.get(f"{self.ORIGIN_SHIELD_URL}/{current_segment}")
        self.assertEqual(response_current.status_code, 200)
        cache_status_current = response_current.headers.get('X-Cache-Status')

        self.assertEqual(cache_status_current, 'MISS',
                         f"Expected MISS for first request to {current_segment}, got {cache_status_current}")

        time.sleep(0.5)

        # Request the next segment
        response_next = requests.get(f"{self.ORIGIN_SHIELD_URL}/{next_segment}")
        self.assertEqual(response_next.status_code, 200)
        cache_status_next = response_next.headers.get('X-Cache-Status')

        self.assertEqual(cache_status_next, 'HIT',
                         f"Expected HIT for prefetched segment {next_segment}, got {cache_status_next}")

if __name__ == '__main__':
    unittest.main(verbosity=2)
