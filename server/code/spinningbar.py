import time
from progress.spinner import PixelSpinner
state="test"
spinner = PixelSpinner('Loading ')
while state != 'FINISHED':
    # Do some work
    spinner.next()
    time.sleep(0.1)