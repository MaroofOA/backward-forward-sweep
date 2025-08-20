
% baseKV = [12660*ones(1,33), 240*ones(1,730-34+1) ];
% Vglm = x(2,:)./baseKV;

load Vglm_100
subplot(211)
plot(Vglm,'ro','MarkerSize',5), hold on, plot(Vallnodes,'b*','MarkerSize',3), hold off
ylabel('V (p.u.)')
xlabel('bus no')
legend('GridLAB-D','OpenDSS')



subplot(212)
plot(abs(Vglm-Vallnodes))
xlabel('bus no')
ylabel('absolute error')
legend('error')