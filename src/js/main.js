// global
const adminPrefix = 'admin@ip-109-45-89-458:~$ ';
const sectionVisibleClass = 'admin-section--visible';
const sectionHiddenClass = 'admin-section--hidden';
const menuFocusedClass = 'menu--focused';
const menuContainer = document.querySelector('#menu');
const menuInput = document.querySelector('#menu-input');

let activeSection;

const addFeedback = (selector, content) => {
	document.querySelector(selector).innerHTML += `${adminPrefix + content}<br/>`
}

// nav
const adminSections = Array.prototype.slice.call(document.querySelectorAll('.admin-section'));

// nav click
const navLinks = Array.prototype.slice.call(document.querySelectorAll('#menu a'));

const navTargets = navLinks.map(n => n.getAttribute('href').replace('#', ''));

const showSection = selector => {
	const targetSection = document.querySelector(selector);

	adminSections.forEach(s => {
		if (s != targetSection) {
			s.classList.add(sectionHiddenClass);
			s.classList.remove(sectionVisibleClass);
			s.removeAttribute('tabindex');
		}
	});

	targetSection.classList.add(sectionVisibleClass);
	targetSection.classList.remove(sectionHiddenClass);
	targetSection.setAttribute('tabindex', '0');
	menu.classList.remove(menuFocusedClass);
	targetSection.querySelector('.admin-input').focus();

	menuInput.innerHTML = '';
	activeSection = selector.replace('#','');
	addFeedback('#menu .feedback', selector.replace('#',''));

	setDate(`${selector} .login-date`);
};

navLinks.forEach(n => n.addEventListener('click', (e) => {
	e.preventDefault();
	const target = e.target.getAttribute('href');

	showSection(target);
}));

// nav type
menuInput.addEventListener('keypress', (e) => {
	if (e.keyCode === 13) {
		e.preventDefault();
		const content = e.target.textContent;

		if (navTargets.indexOf(content) >= 0) {
			showSection(`#${content}`);
		} else {
			addFeedback('#menu .feedback', `${content}<br/>-bash: ${content}: command not found`)
			menuInput.innerHTML = '';
		}
	}
});

menuInput.addEventListener('focus', (e) => {
	menu.classList.add(menuFocusedClass);
});

// undo nav type focus
menu.addEventListener('click', (e) => {
	if (e.target.tagName.toLowerCase() !== 'a') {
		menu.classList.add(menuFocusedClass);
		menuInput.focus();
	}
});

adminSections.forEach(s => {
	s.addEventListener('focus', () => menu.classList.remove(menuFocusedClass));
	s.addEventListener('click', () => menu.classList.remove(menuFocusedClass));

	// bind individual section inputs
	const commandLinks = Array.prototype.slice.call(s.querySelectorAll('a'));
	const commands = commandLinks.map(a => a.textContent.replace('--', ''));

	s.querySelector('.admin-input').addEventListener('keypress', (e) => {
		if (e.keyCode === 13) {
			e.preventDefault();
			const content = e.target.textContent;
			const command = content.split('--')[1];

			if (commands.indexOf(command) >= 0) {
				addFeedback(`#${s.id} .feedback`, `${content}`);
			} else {
				addFeedback(`#${s.id} .feedback`, `${content}<br/>-bash: ${content}: command not found`)
			}
			e.target.innerHTML = '';
		}
	});

	commandLinks.forEach(c => c.addEventListener('click', () => {
		addFeedback(`#${s.id} .feedback`, `${activeSection} ${c.textContent}`);
	}));
});

// for displaying dates on windows
const setDate = selector => {
	const stringDate = new Date().toString().split(' GMT')[0];
	document.querySelector(selector).innerHTML = stringDate;
}

setDate('#menu .login-date');