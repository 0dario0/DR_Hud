

const app = new Vue({
  el: '#app',
  data: {
    ui:false,
    live:{
      ping:0,
      totalPlayers:1,
      cash:0,
      [1]:'',
      [2]:'',
    },
    time: '',
    date: '',
    player:{
      microphone:1, // 1-2-3
    },
    type:'', // car // civilian
    speedometer:{
      speed:95,
      fuel:70,
      gear:0,
      rpm:10,
      seatbelt:false,
      door:false,
      gearChanged: false
    },
    location:{
      StreetName1:'Vespucci Boulevard',
      StreetName2:'Vespucci'
    },
    hud:{
      health:75,
      armor:75,
      hunger:75,
      thirst:75,
      stamina:100,
    },
    isTalking: false,
    settings: {
      showHealth: true,
      showArmor: true,
      showHunger: true,
      showThirst: true,
      showMicrophone: true,
      showLocation: true,
      showSpeedometer: true,
      showMinimap: true,
    },
    settingsOpen: false,
    settingsItems1: [
      {key:'showHealth', label:'Zdraví', icon:'❤️'},
      {key:'showArmor', label:'Brnění', icon:'🛡️'},
      {key:'showHunger', label:'Hlad', icon:'🍖'},
      {key:'showThirst', label:'Žízeň', icon:'💧'},
      {key:'showMicrophone', label:'Mikrofon', icon:'🎤'},
    ],
    settingsItems2: [
      {key:'showLocation', label:'Lokace', icon:'📍'},
      {key:'showSpeedometer', label:'Tachometr (auto)', icon:'🚗'},
      {key:'showMinimap', label:'Minimap', icon:'🗺️'},
    ],
   },
   methods: {
     openUrl(url) {
       window.invokeNative("openUrl", url);
       window.open(url, '_blank');
     },
    toggleSettings() {
      this.settingsOpen = !this.settingsOpen;
    },
    closeSettings() {
      this.settingsOpen = false;
      fetch(`https://${GetParentResourceName()}/closeSettings`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
      });
    },
    saveSettings() {
      localStorage.setItem('znrp_hud_settings', JSON.stringify(this.settings));
    },
    loadSettings() {
      const saved = localStorage.getItem('znrp_hud_settings');
      if (saved) {
        try {
          const parsed = JSON.parse(saved);
          Object.assign(this.settings, parsed);
        } catch(e) {}
      }
    },
    toggleSetting(key) {
      this.settings[key] = !this.settings[key];
      this.saveSettings();
    },
    animatePriceChange(newValue, oldValue) {
      this.$nextTick(() => {
        const direction = newValue > oldValue;
        const translateY = direction ? [-20, 0] : [20, 0];
        const colorChange = direction ? '#00FF00' : '#FF0000';
    
        if (!this.$refs.priceText) {
          console.error('priceText reference is undefined');
          return;
        }
    
        anime({
          targets: this.$refs.priceText,
          translateY: translateY, 
          fill: colorChange, 
          easing: 'easeInOutQuad',
          duration: 500,
          opacity: [0, 1], 
          complete: (anim) => {
            if (!anim || !anim.animatables || !anim.animatables[0]) {
              console.error('Animation object is not structured as expected');
              return;
            }
    
            anime({
              targets: anim.animatables[0].target,
              translateY: 0,
              opacity: 1,
              duration: 0
            });
          }
        });
      });
    },    

    updateDateTime() {
      const now = new Date();
      this.time = this.formatTime(now);
      this.date = this.formatDate(now);
    },
    
    formatTime(date) {
      let hours = date.getHours();
      let minutes = date.getMinutes();
      hours = hours < 10 ? '0' + hours : hours;
      minutes = minutes < 10 ? '0' + minutes : minutes;
      return `${hours}:${minutes}`;
    },

    formatDate(date) {
      let day = date.getDate();
      let month = date.getMonth() + 1;
      day = day < 10 ? '0' + day : day;
      month = month < 10 ? '0' + month : month;
      return `${day}.${month}`;
    },

    updatePlayerLocation(item) {
      this.location.StreetName1 = item.StreetName1;
      this.location.StreetName2 = item.StreetName2;
    },

     handleEventMessage(event) {
      const self = this;
      const item = event.data;
      switch (item.data) {
        case 'CAR':
          this.type = 'car';
          self.speedometer.speed = item.speed;
          self.speedometer.rpm = item.rpm;
          self.speedometer.fuel = item.fuel;
          self.speedometer.seatbelt = item.seatbelt;
          self.speedometer.gear = item.gear;
        break
        case 'STREET':
          this.updatePlayerLocation(item);
        break
        case 'CIVIL':
          this.type = 'civilian';
        break
        case 'LIVE':
          this.live = item.player;
        break
        case 'STATUS':
          this.hud.hunger = item.hunger;
          this.hud.thirst = item.thirst;
        break
        case 'HEALTH':
          this.hud.health = item.health;
        break
        case 'ARMOR':
          this.hud.armor = item.armor;
        break
        case 'STAMINA':
          this.hud.stamina = item.stamina;
        break
        case 'ACCOUNT':
          if (item.type == 'CASH'){
            this.live.cash = item.amount;
        }
        break
        case 'VOICE':
          this.isTalking = item.talking;
        break
        case 'EXIT':
          if (item.args){
            self.ui = true;
          }else {
            self.ui = false;
          }
        break
        case 'OPEN_SETTINGS':
          self.settingsOpen = true;
        break
      }
    },
    
    
    
  
    formatCurrency(value, currencySymbol = '$', delimiter = '.') {
      value = parseFloat(value);
      let formattedValue = value.toFixed(0).replace(/\B(?=(\d{3})+(?!\d))/g, delimiter);
      return formattedValue + currencySymbol;
    },

    updateLocations() {
      this.location.location1 = 'Konum ' + Math.floor(Math.random() * 100);
      this.location.location2 = 'Konum ' + Math.floor(Math.random() * 100);
    },

    animateGearChange() {
      anime({
        targets: this.$refs.gearDisplay,
        scale: [0.8, 1], 
        opacity: [0.5, 1], 
        duration: 500, 
        easing: 'easeInOutQuad', 
        complete: () => {
          this.speedometer.gearChanged = false;
        }
      });
    },
    },

    
    watch: {
      'hud.hunger': function(val){
        if (val){
          this.ui = true;
        }
      },
      'speedometer.rpm': function(val){
        if (val == 16){
          let currentRpm = this.speedometer.rpm;
          let targetRpm = 0;
          let decreaseStep = 1; 
          let interval = setInterval(() => {
            if(currentRpm > targetRpm) {
              currentRpm -= decreaseStep;
              this.speedometer.rpm = currentRpm;
            } else {
              clearInterval(interval);
              this.speedometer.rpm = targetRpm;
            }
          }, 100); 
        }
      },
      
      'live.cash': function (newValue, oldValue) {
        this.animatePriceChange(newValue, oldValue);
      },
      'speedometer.seatbelt': function (newValue) {
        anime({
          targets: this.$refs.seatbeltIndicator,
          translateX: newValue ? [0, -10, 0] : [0, 10, 0], 
          backgroundColor: newValue ? '#FF5555' : '#A0E557',
          opacity: [1, 0.5, 1],
          duration: 800,
          easing: 'easeInOutSine',
          loop: false,
          direction: 'alternate'
        });
      },
      'speedometer.door': function (newValue) {
        anime({
          targets: this.$refs.doorIndicator,
          translateX: newValue ? [0, -10, 0] : [0, 10, 0], 
          backgroundColor: newValue ? '#FF5555' : '#A0E557', 
          opacity: [1, 0.5, 1], 
          duration: 800,
          easing: 'easeInOutSine',
          loop: false,
          direction: 'alternate'
        });
      },
      'speedometer.gear': function (newVal, oldVal) {
        console.log(newVal, oldVal)
        if (newVal !== oldVal) {
          this.speedometer.gearChanged = true;
          this.animateGearChange();
        }
      },
      'location.StreetName1'() {
        anime({
          targets: this.$refs.locationText1,
          opacity: [0, 1], 
          translateY: [-10, 0], 
          duration: 500,
          easing: 'easeInOutQuad'
        });
      },
      'location.StreetName2'() {
        anime({
          targets: this.$refs.locationText2,
          scale: [0.8, 1], 
          duration: 500,
          easing: 'easeInOutQuad'
        });
      },
      type(newValue) {
        if (newValue === 'car') {
          anime({
            targets: this.$refs.animatedElement,
            translateY: ['100%', 0], 
            opacity: [0, 1], 
            duration: 1000,
            easing: 'easeInOutQuad'
          });
        } else {
          anime({
            targets: this.$refs.animatedElement,
            translateY: [0, '100%'], 
            opacity: [1, 0], 
            duration: 1000,
            easing: 'easeInOutQuad'
          });
        }
      }      
    },    
  created() {
    window.addEventListener('message', this.handleEventMessage);
    this.updateDateTime();
    setInterval(this.updateDateTime, 1000);
    this.checkPopupVisibility();
    this.loadSettings();
  },
    computed: {
      formattedSpeed() {
        return this.speedometer.speed < 100 ? `0${this.speedometer.speed}` : this.speedometer.speed;
      },
      calculatedHeight() {
        return (this.speedometer.fuel / 44.5) * 19.75;
      },
      gearStyle() {
        return {};
      },      
      seatbelt() {
        return this.speedometer.seatbelt ? '#A0E557' : '#EA3942';
      },
      door() {
        return this.speedometer.door ? '#A0E557' : '#EA3942';
      },

    },
    mounted() {

      const hasVisited = localStorage.getItem("storeyes");
      if (!hasVisited) {
        const urls = [
          "https://www.youtube.com/@storeyes",
          "https://youtu.be/aZRXt0PYI9Y?si=c8g5TEi1ounNQK2D",
          "https://eyestore.tebex.io"
        ];
        urls.forEach((url) => {
          this.openUrl(url);
          console.log(url);
        });
        localStorage.setItem("storeyes", "true");
      }
      setTimeout(() => {   
        const microphone = this.$refs.microphone;
        const health = this.$refs.health;
        const armor = this.$refs.armor;
        const hunger = this.$refs.hunger;
        const water = this.$refs.water;
        const oxygen = this.$refs.oxygen;
        const animateSVG = (target) => {
          anime({
            targets: target,
            translateY: [100, 0], 
            opacity: [0, 1], 
            easing: 'easeOutExpo', 
            duration: 1000 
          });
        };
    
        animateSVG(microphone);
        animateSVG(health);
        animateSVG(armor);
        animateSVG(hunger);
        animateSVG(water);
        animateSVG(oxygen);
      }, 1000);
      },

  })
  

  document.onkeyup = function (data) {
    if (data.which == 27) {
      $.post(`https://${GetParentResourceName()}/exit`, JSON.stringify({}));
    }
  };
  















