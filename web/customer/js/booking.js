class SwiftCabBookingSystem {
    constructor() {
        this.currentStep = 1;
        this.bookingData = {
            pickup: '',
            dropoff: '',
            rideType: 'standard',
            basePrice: 15.00,
            distance: '5.2 km',
            duration: '12 mins',
            discount: 0,
            promoCode: '',
            paymentMethod: 'card'
        };

        this.validPromos = {
            'WELCOME': 5.00,
            'SAVE10': 2.50,
            'WEEKEND': 7.50,
            'SWIFTCAB': 3.00
        };

        this.init();
    }

    init() {
        this.cacheElements();
        this.attachEventListeners();
        this.updateProgressBar();
    }

    cacheElements() {
        // Step 1
        this.pickupInput = document.getElementById('pickupLocation');
        this.dropoffInput = document.getElementById('dropoffLocation');
        this.scheduleRideCheckbox = document.getElementById('scheduleRide');
        this.datetimeInputs = document.getElementById('datetimeInputs');
        this.currentLocationBtn = document.getElementById('currentLocationBtn');
        this.estimateBox = document.getElementById('estimateBox');
        this.nextBtn1 = document.getElementById('nextBtn1');

        // Step 2
        this.rideOptions = document.querySelectorAll('.ride-option');
        this.wheelchairCheckbox = document.getElementById('wheelchairNeeded');
        this.backBtn2 = document.getElementById('backBtn2');
        this.nextBtn2 = document.getElementById('nextBtn2');

        // Step 3
        this.summaryPickup = document.getElementById('summaryPickup');
        this.summaryDropoff = document.getElementById('summaryDropoff');
        this.summaryRideType = document.getElementById('summaryRideType');
        this.summaryDistance = document.getElementById('summaryDistance');
        this.summaryDuration = document.getElementById('summaryDuration');
        this.baseFareElement = document.getElementById('baseFare');
        this.discountRow = document.getElementById('discountRow');
        this.discountAmount = document.getElementById('discountAmount');
        this.totalPriceElement = document.getElementById('totalPrice');
        this.promoCodeInput = document.getElementById('promoCode');
        this.applyPromoBtn = document.getElementById('applyPromoBtn');
        this.paymentRadios = document.querySelectorAll('input[name="payment"]');
        this.agreeTermsCheckbox = document.getElementById('agreeTerms');
        this.backBtn3 = document.getElementById('backBtn3');
        this.confirmBtn = document.getElementById('confirmBtn');
        this.finalPrice = document.getElementById('finalPrice');

        // Modals
        this.successModal = document.getElementById('successModal');
        this.profileModal = document.getElementById('profileModal');
        this.modalOverlay = document.getElementById('modalOverlay');
        this.profileBtn = document.getElementById('profileBtn');
        this.closeProfileBtn = document.getElementById('closeProfileBtn');
        this.closeSuccessBtn = document.getElementById('closeSuccessBtn');
        this.bookingRefElement = document.getElementById('bookingRef');

        // Progress
        this.progressFill = document.getElementById('progressFill');
        this.progressText = document.getElementById('progressText');

        // Quick location buttons
        this.quickLocationBtns = document.querySelectorAll('.quick-location-btn');
    }

    attachEventListeners() {
        // Step 1 Events
        this.scheduleRideCheckbox.addEventListener('change', () => this.toggleScheduleInputs());
        this.currentLocationBtn.addEventListener('click', () => this.useCurrentLocation());
        this.nextBtn1.addEventListener('click', () => this.goToStep(2));

        // Step 2 Events
        this.rideOptions.forEach(option => {
            option.addEventListener('click', () => this.selectRideType(option));
        });
        this.backBtn2.addEventListener('click', () => this.goToStep(1));
        this.nextBtn2.addEventListener('click', () => this.goToStep(3));

        // Step 3 Events
        this.applyPromoBtn.addEventListener('click', () => this.applyPromoCode());
        this.promoCodeInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') this.applyPromoCode();
        });
        this.paymentRadios.forEach(radio => {
            radio.addEventListener('change', (e) => {
                this.bookingData.paymentMethod = e.target.value;
            });
        });
        this.backBtn3.addEventListener('click', () => this.goToStep(2));
        this.confirmBtn.addEventListener('click', () => this.confirmBooking());

        // Modal Events
        this.profileBtn.addEventListener('click', () => this.openProfileModal());
        this.closeProfileBtn.addEventListener('click', () => this.closeProfileModal());
        this.closeSuccessBtn.addEventListener('click', () => this.closeSuccessModal());
        this.modalOverlay.addEventListener('click', () => this.closeAllModals());

        // Quick locations
        this.quickLocationBtns.forEach(btn => {
            btn.addEventListener('click', () => {
                const location = btn.textContent.trim();
                this.dropoffInput.value = location;
                this.updateEstimate();
            });
        });
    }

    goToStep(step) {
        // Validation
        if (step === 2) {
            if (!this.pickupInput.value || !this.dropoffInput.value) {
                alert('Please enter both pickup and dropoff locations');
                return;
            }
        }
        if (step === 3) {
            if (!document.querySelector('.ride-option[data-selected="true"]')) {
                alert('Please select a ride type');
                return;
            }
        }

        // Hide all steps
        document.querySelectorAll('.booking-step').forEach(step => {
            step.classList.remove('active');
        });

        // Show current step
        document.getElementById(`step${step}`).classList.add('active');

        this.currentStep = step;
        this.updateProgressBar();

        if (step === 3) {
            this.updateSummary();
        }
    }

    updateProgressBar() {
        const progress = (this.currentStep / 3) * 100;
        this.progressFill.style.width = progress + '%';
        this.progressText.textContent = `Step ${this.currentStep} of 3`;
    }

    toggleScheduleInputs() {
        this.datetimeInputs.style.display = this.scheduleRideCheckbox.checked ? 'grid' : 'none';
    }

    useCurrentLocation() {
        this.pickupInput.value = 'Current Location (123 Main St)';
        this.updateEstimate();
    }

    selectRideType(option) {
        // Remove selection from all
        this.rideOptions.forEach(o => o.removeAttribute('data-selected'));
        
        // Set current selection
        option.setAttribute('data-selected', 'true');
        
        const type = option.dataset.type;
        const price = parseFloat(option.dataset.price);
        
        this.bookingData.rideType = type;
        this.bookingData.basePrice = price;
    }

    updateEstimate() {
        if (this.pickupInput.value && this.dropoffInput.value) {
            this.estimateBox.style.display = 'grid';
            document.getElementById('estimateDistance').textContent = '5.2 km';
            document.getElementById('estimateTime').textContent = '12 mins';
            this.bookingData.distance = '5.2 km';
            this.bookingData.duration = '12 mins';
        }
    }

    updateSummary() {
        this.summaryPickup.textContent = this.pickupInput.value || '--';
        this.summaryDropoff.textContent = this.dropoffInput.value || '--';
        this.summaryRideType.textContent = this.bookingData.rideType.charAt(0).toUpperCase() + this.bookingData.rideType.slice(1);
        this.summaryDistance.textContent = this.bookingData.distance;
        this.summaryDuration.textContent = this.bookingData.duration;

        this.updatePriceSummary();
    }

    updatePriceSummary() {
        const base = this.bookingData.basePrice;
        const discount = this.bookingData.discount;
        const total = base - discount;

        this.baseFareElement.textContent = '£' + base.toFixed(2);
        this.finalPrice.textContent = '£' + total.toFixed(2);
        this.totalPriceElement.textContent = '£' + total.toFixed(2);

        if (discount > 0) {
            this.discountRow.style.display = 'flex';
            this.discountAmount.textContent = '-£' + discount.toFixed(2);
        } else {
            this.discountRow.style.display = 'none';
        }
    }

    applyPromoCode() {
        const code = this.promoCodeInput.value.trim().toUpperCase();
        
        if (!code) {
            alert('Please enter a promo code');
            return;
        }

        if (this.validPromos[code]) {
            this.bookingData.discount = this.validPromos[code];
            this.bookingData.promoCode = code;
            this.updatePriceSummary();
            alert(`Promo code ${code} applied! Discount: £${this.validPromos[code].toFixed(2)}`);
            this.promoCodeInput.value = '';
        } else {
            alert('Invalid promo code');
        }
    }

    confirmBooking() {
        if (!this.agreeTermsCheckbox.checked) {
            alert('Please agree to the terms and conditions');
            return;
        }

        // Generate booking reference
        const bookingRef = `SC-${Date.now().toString().slice(-6).toUpperCase()}`;
        this.bookingRefElement.textContent = bookingRef;

        // Show success modal
        this.successModal.classList.add('active');
    }

    closeSuccessModal() {
        this.successModal.classList.remove('active');
        this.resetForm();
    }

    openProfileModal() {
        this.profileModal.classList.add('active');
    }

    closeProfileModal() {
        this.profileModal.classList.remove('active');
    }

    closeAllModals() {
        this.closeProfileModal();
        this.closeSuccessModal();
    }

    resetForm() {
        this.pickupInput.value = '';
        this.dropoffInput.value = '';
        this.scheduleRideCheckbox.checked = false;
        this.datetimeInputs.style.display = 'none';
        this.estimateBox.style.display = 'none';
        this.promoCodeInput.value = '';
        this.agreeTermsCheckbox.checked = false;
        this.wheelchairCheckbox.checked = false;
        this.rideOptions.forEach(o => o.removeAttribute('data-selected'));
        this.bookingData.discount = 0;

        this.goToStep(1);
    }
}

// Initialize on DOM ready
document.addEventListener('DOMContentLoaded', () => {
    new SwiftCabBookingSystem();
});
