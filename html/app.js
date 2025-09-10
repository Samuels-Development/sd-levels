let skillsData = [];

function updateSkills(skills) {
    skillsData = Object.values(skills);
    renderSkills();
}

function renderSkills() {
    const skillsGrid = document.getElementById('skills-grid');
    skillsGrid.innerHTML = '';

    skillsData.forEach(skill => {
        const skillItem = document.createElement('div');
        skillItem.className = 'skill-item';
        
        const progressPercent = skill.progress || (skill.xp % 100);
        
        skillItem.innerHTML = `
            <div class="skill-header">
                <span class="skill-name">${skill.name}</span>
                <div class="skill-info">
                    <span class="skill-xp">XP: ${skill.xp}</span>
                    <span class="skill-level">Level ${skill.level}</span>
                </div>
            </div>
            <div class="skill-description">${skill.description || 'No description available'}</div>
            <div class="skill-progress">
                <div class="skill-progress-bar" style="width: ${progressPercent}%">
                    <span class="progress-text">${Math.round(progressPercent)}%</span>
                </div>
            </div>
        `;
        skillsGrid.appendChild(skillItem);
    });
}

function toggleUI(show) {
    const body = document.body;
    const tabletFrame = document.getElementById('tablet-frame');
    
    if (show) {
        body.classList.add('active');
        tabletFrame.style.display = 'flex';
        // Small delay to ensure smooth transition
        setTimeout(() => {
            tabletFrame.style.opacity = '1';
        }, 10);
    } else {
        tabletFrame.style.opacity = '0';
        setTimeout(() => {
            body.classList.remove('active');
            tabletFrame.style.display = 'none';
        }, 300);
    }
}

function closeUI() {
    toggleUI(false);
    fetch('https://immense-skills/closeUI', {method: 'POST'});
}

// Event Listeners
window.addEventListener('message', (event) => {
    if (event.data.action === 'updateSkills') {
        updateSkills(event.data.skills);
    } else if (event.data.action === 'toggleUI') {
        toggleUI(event.data.show);
    }
});

document.getElementById('close-button').addEventListener('click', closeUI);

document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape' || event.key === 'Backspace') {
        event.preventDefault();
        closeUI();
    }
});

// Initialize with empty skills if needed
renderSkills();