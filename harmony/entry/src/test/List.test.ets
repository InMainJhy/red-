import localUnitTest from './LocalUnit.test';
import responsiveLayoutTest from './ResponsiveLayout.test';
import meetingPersistenceTest from './MeetingPersistence.test';
import launchIntentTest from './LaunchIntent.test';

export default function testsuite() {
  localUnitTest();
  responsiveLayoutTest();
  meetingPersistenceTest();
  launchIntentTest();
}
