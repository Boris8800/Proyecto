/**
 * Booking Page JavaScript
 * Handles the multi-step booking flow and interactions
 */

class BookingSystem {
    constructor() {
        this.currentStep = 1;
        this.bookingData = {
            pickup: '',
            destination: '',
            rideType: 'standard',
            scheduled: false,
            scheduleDate: '',
            scheduleTime: '',
            distance: 0,
            duration: 0,
            price: 12.50,
            promoCode: '',
            promoDiscount: 0
        };

        this.rideTypePrices = {
            standard: 12.50,
            premium: 18.00,
            xl: 22.00
        };

        this.init();
    }

    init() {
        this.setupEventListeners();
        this.loadUserData();
    }

    setupEventListeners() {
        // Step Navigation
        document.getElementById('nextToRideType')?.addEventListener('click', () => this.nextStep());
        document.getElementById('nextToConfirm')?.addEventListener('click', () => this.nextStep());
        document.getElementById('backToLocation')?.addEventListener('click', () => this.prevStep());
        document.getElementById('backToRideType')?.addEventListener('click', () => this.prevStep());

        // Location Inputs
        document.getElementById('useCurrentLocation')?.addEventListener('click', () => this.useCurrentLocation());
        document.getElementById('pickupInput')?.addEventListener('focus', () => this.showRecent('pickup'));
        document.getElementById('destinationInput')?.addEventListener('focus', () => this.showRecent('destination'));

        // Schedule Ride
        document.getElementById('scheduleRide')?.addEventListener('change', (e) => {
            this.toggleScheduleDateTime(e.target.checked);
        });

        // Ride Type Selection
        document.querySelectorAll('.ride-type-card').forEach(card => {
            card.addEventListener('click', () => this.selectRideType(card));
        });

        // Confirm Booking
        document.getElementById('confirmBooking')?.addEventListener('click', () => this.confirmBooking());

        // Promo Code
        document.querySelector('.btn-apply-promo')?.addEventListener('click', () => this.applyPromo());

        // Modal Buttons
        document.getElementById('helpBtn')?.addEventListener('click', () => this.showModal('helpModal'));
        document.querySelectorAll('.btn-close-modal').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.target.closest('.modal').classList.remove('active');
            });
        });

        document.getElementById('viewRideStatus')?.addEventListener('click', () => {
            this.showModal('');
            document.getElementById('rideStatus').style.display = 'block';
        });
    }

    loadUserData() {
        // Simulate loading user data
        // In real app, this would come from the backend
        const userName = 'Maria';
        document.querySelector('.user-profile')?.innerHTML = `
            <img src="https://ui-avatars.com/api/?name=${userName}&background=4facfe&color=fff" alt="Customer">
            <span>${userName} S.</span>
        `;
    }

    // Step Navigation
    goToStep(step) {
        if (step < 1 || step > 3) return;

        // Hide all steps
        document.querySelectorAll('.booking-step').forEach(s => {
            s.classList.remove('active');
        });

        // Deactivate all step indicators
        document.querySelectorAll('.step').forEach((s, idx) => {
            if (idx + 1 <= step) {
                s.classList.add('active');
            } else {
                s.classList.remove('active');
            }
        });

        // Show current step
        document.getElementById(`step${step}`)?.classList.add('active');
        this.currentStep = step;

        // Update confirmation details when going to step 3
        if (step === 3) {
            this.updateConfirmationDetails();
        }

        // Scroll to top
        document.querySelector('.booking-card').scrollTop = 0;
    }

    nextStep() {
        if (this.currentStep === 1) {
            if (!this.validateStep1()) return;
        } else if (this.currentStep === 2) {
            if (!this.validateStep2()) return;
        }
        this.goToStep(this.currentStep + 1);
    }

    prevStep() {
        this.goToStep(this.currentStep - 1);
    }

    // Validation
    validateStep1() {
        const pickup = document.getElementById('pickupInput')?.value.trim();
        const destination = document.getElementById('destinationInput')?.value.trim();

        if (!pickup || !destination) {
            alert('Please enter both pickup and destination locations');
            return false;
        }

        this.bookingData.pickup = pickup;
        this.bookingData.destination = destination;
        this.bookingData.scheduled = document.getElementById('scheduleRide')?.checked || false;

        if (this.bookingData.scheduled) {
            const date = document.getElementById('scheduleDate')?.value;
            const time = document.getElementById('scheduleTime')?.value;
            if (!date || !time) {
                alert('Please select schedule date and time');
                return false;
            }
            this.bookingData.scheduleDate = date;
            this.bookingData.scheduleTime = time;
        }

        // Simulate distance calculation
        this.bookingData.distance = (Math.random() * 15 + 5).toFixed(1);
        this.bookingData.duration = Math.ceil(this.bookingData.distance * 2);
        this.showQuote();

        return true;
    }

    validateStep2() {
        const selected = document.querySelector('.ride-type-card.active');
        if (!selected) {
            alert('Please select a ride type');
            return false;
        }
        return true;
    }

    // Location Functions
    useCurrentLocation() {
        this.bookingData.pickup = 'Current Location';
        document.getElementById('pickupInput').value = 'Current Location';
        document.getElementById('pickupRecent').style.display = 'none';
    }

    showRecent(type) {
        const recentEl = document.getElementById(`${type}Recent`);
        if (recentEl) {
            recentEl.style.display = 'block';
        }

        // Hide on blur
        const inputEl = document.getElementById(`${type}Input`);
        inputEl?.addEventListener('blur', () => {
            setTimeout(() => {
                recentEl.style.display = 'none';
            }, 200);
        }, { once: true });
    }

    showQuote() {
        const quoteSection = document.getElementById('quoteSection');
        if (quoteSection) {
            document.getElementById('distanceDisplay').textContent = this.bookingData.distance;
            document.getElementById('timeDisplay').textContent = this.bookingData.duration;
            quoteSection.style.display = 'block';
        }
    }

    // Schedule Ride
    toggleScheduleDateTime(show) {
        const scheduleDateTime = document.getElementById('scheduleDateTime');
        if (scheduleDateTime) {
            scheduleDateTime.style.display = show ? 'grid' : 'none';
        }
    }

    // Ride Type Selection
    selectRideType(card) {
        // Remove active class from all cards
        document.querySelectorAll('.ride-type-card').forEach(c => {
            c.classList.remove('active');
        });

        // Add active class to clicked card
        card.classList.add('active');

        // Update booking data
        const rideType = card.dataset.type;
        const price = parseFloat(card.dataset.price);
        this.bookingData.rideType = rideType;
        this.bookingData.price = price;

        // Update total price display (if visible)
        this.updatePriceDisplay();
    }

    updatePriceDisplay() {
        const baseFare = this.bookingData.price;
        const serviceFee = 0.50;
        const discount = this.bookingData.promoDiscount;
        const total = baseFare + serviceFee - discount;

        document.getElementById('baseFare').textContent = `$${baseFare.toFixed(2)}`;
        document.getElementById('totalPrice').textContent = `$${Math.max(0, total).toFixed(2)}`;
    }

    // Promo Code
    applyPromo() {
        const promoCode = document.getElementById('promoCode')?.value.trim().toUpperCase();

        if (!promoCode) {
            alert('Please enter a promo code');
            return;
        }

        // Simulate promo code validation
        const validPromos = {
            'SAVE10': 2.00,
            'WELCOME': 5.00,
            'WEEKEND': 3.50
        };

        if (validPromos[promoCode]) {
            this.bookingData.promoDiscount = validPromos[promoCode];
            const promoRow = document.getElementById('promoRow');
            if (promoRow) {
                document.getElementById('promoDiscount').textContent = `-$${this.bookingData.promoDiscount.toFixed(2)}`;
                promoRow.style.display = 'flex';
            }
            alert(`Promo code "${promoCode}" applied successfully!`);
            this.updatePriceDisplay();
        } else {
            alert('Invalid promo code');
        }
    }

    // Confirmation
    updateConfirmationDetails() {
        // Route Summary
        document.getElementById('confirmPickup').textContent = this.bookingData.pickup;
        document.getElementById('confirmDestination').textContent = this.bookingData.destination;

        // Ride Details
        const rideTypeDisplay = this.bookingData.rideType.charAt(0).toUpperCase() + this.bookingData.rideType.slice(1);
        document.getElementById('confirmRideType').textContent = rideTypeDisplay;
        document.getElementById('confirmDistance').textContent = `${this.bookingData.distance} km`;
        document.getElementById('confirmDuration').textContent = `${this.bookingData.duration} min`;

        // Update prices
        this.updatePriceDisplay();
    }

    confirmBooking() {
        // Simulate booking confirmation
        const bookingRef = `QB-${new Date().getFullYear()}-${Math.floor(Math.random() * 1000000).toString().padStart(6, '0')}`;
        
        // Show success modal
        document.getElementById('bookingRef').textContent = bookingRef;
        document.getElementById('successEta').textContent = '3 minutes';
        this.showModal('successModal');

        // Reset form after 5 seconds
        setTimeout(() => {
            this.resetForm();
        }, 5000);
    }

    resetForm() {
        this.bookingData = {
            pickup: '',
            destination: '',
            rideType: 'standard',
            scheduled: false,
            scheduleDate: '',
            scheduleTime: '',
            distance: 0,
            duration: 0,
            price: 12.50,
            promoCode: '',
            promoDiscount: 0
        };

        document.getElementById('locationForm').reset();
        document.getElementById('scheduleRide').checked = false;
        document.getElementById('scheduleDateTime').style.display = 'none';
        document.getElementById('quoteSection').style.display = 'none';

        // Reset ride type selection
        document.querySelectorAll('.ride-type-card').forEach((c, idx) => {
            if (idx === 0) {
                c.classList.add('active');
            } else {
                c.classList.remove('active');
            }
        });

        // Reset step
        this.goToStep(1);

        // Hide modal and show ride status
        document.getElementById('successModal').classList.remove('active');
        document.getElementById('rideStatus').style.display = 'block';
    }

    // Modal Management
    showModal(modalId) {
        document.querySelectorAll('.modal').forEach(m => m.classList.remove('active'));
        if (modalId) {
            document.getElementById(modalId)?.classList.add('active');
        }
    }
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
    const bookingSystem = new BookingSystem();

    // Close modal on outside click
    document.querySelectorAll('.modal').forEach(modal => {
        modal.addEventListener('click', (e) => {
            if (e.target === modal) {
                modal.classList.remove('active');
            }
        });
    });

    // Close ride status card
    document.getElementById('closeStatus')?.addEventListener('click', () => {
        document.getElementById('rideStatus').style.display = 'none';
    });
});
