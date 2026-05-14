import localUnitTest from './LocalUnit.test';
import responsiveLayoutTest from './ResponsiveLayout.test';
import meetingPersistenceTest from './MeetingPersistence.test';

export default function testsuite() {
  localUnitTest();
  responsiveLayoutTest();
  meetingPersistenceTest();
}
