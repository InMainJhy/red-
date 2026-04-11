# Harmony

褰撳墠 HarmonyOS 鍓嶇鐩存帴淇敼浜庯細

`/Users/mychanging/Desktop/hackhathon/harmony`

## 褰撳墠椤甸潰

- `pages/Index`
  鍗曢〉绉诲姩宸ヤ綔鍙帮紝搴曢儴涓夋寜閽垏鎹?`瑙掕壊 / 璁細 / 绾`
- `pages/ProfileDetail`
  鏃х増瑙掕壊璇︽儏瀛愰〉锛屽綋鍓嶄繚鐣欎綔鍙傝€?- `pages/Arena`
  鏃х増璁細瀛愰〉锛屽綋鍓嶄繚鐣欎綔鍙傝€?
## 鏁版嵁缁撴瀯

- `entry/src/main/ets/common/Models.ets`
- `entry/src/main/ets/service/PersonaApi.ets`

褰撳墠棣栭〉宸茬粡鎺ュ叆鐪熷疄鍚庣浼樺厛鐨?service 灞傦細

- 榛樿浜虹墿锛?  - `GET /api/presets`
  - `GET /api/profiles/:profileId`
- 鑷畾涔変汉鐗╋細
  - `POST /api/timeline/parse`
  - `POST /api/agents/build`
- Arena锛?  - `POST /api/arena/run`

The frontend now uses API responses only.
## 鑱旂綉璇存槑

褰撳墠 `PersonaApi.ets` 榛樿浼氫緷娆″皾璇曚互涓嬪悗绔湴鍧€锛?
- `http://192.168.51.148:3030`
- `http://10.0.2.2:3030`
- `http://127.0.0.1:3030`
- `http://localhost:3030`

璇存槑锛?
- `192.168.51.148` 鏄繖鍙板紑鍙戞満鍦ㄥ綋鍓嶇綉缁滀笅鐨勫眬鍩熺綉 IP锛岄€傚悎鎵嬫満鐪熸満鐩磋繛銆?- 濡傛灉鍚庣画鍒囨崲 Wi-Fi锛岃繖涓?IP 鍙兘鍙樺寲锛岄渶瑕佸悓姝ヤ慨鏀?`entry/src/main/ets/service/PersonaApi.ets`銆?- 宸ョ▼宸茬粡琛ヤ笂 `ohos.permission.INTERNET`锛屽惁鍒欑湡鏈烘棤娉曡闂悗绔€?
## 瀹樻柟鏂囨。鍙傝€?
- HarmonyOS 瀹樻柟鐭ヨ瘑鍦板浘涓殑 ArkUI 璺敱涓庨〉闈㈢粍缁囩浉鍏虫枃妗?- `浣跨敤Navigation瀵艰埅`
  https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-navigation-navigation
- `HTTP鏁版嵁璇锋眰`
  https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/http-request
- `鐘舵€佺鐞嗘渶浣冲疄璺礰
  https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-status-management
- HarmonyOS 瀹樻柟 Codelab 涓叧浜?`router.pushUrl` / 椤甸潰鍙傛暟浼犻€掔殑绀轰緥
  褰撳墠 MVP 閲囩敤鏇寸ǔ鐨?`router.pushUrl + getParams` 鏂瑰紡鍋氬椤佃烦杞?
## 璇存槑

褰撳墠鏈哄櫒鍙互閫氳繃 DevEco Studio 鑷甫鐨?`hvigor` 鎷夎捣鍛戒护琛屾瀯寤猴紝浣嗚繖濂?SDK 缁勪欢褰撳墠涓嶅畬鏁达紝鍛戒护琛岄瑙堟瀯寤轰細鎶?`SDK component missing`銆傚缓璁湪 DevEco Studio 涓ˉ榻?SDK 缁勪欢鍚庯紝鍐嶆墦寮€ `harmony` 鐩綍鎵ц棰勮鎴栫湡鏈鸿繍琛屻€?



